import pytest
from app.services.rule_engine import validate_compliance

def test_all_fields_present_domestic():
    extracted = {
        "mrp": "Rs. 99.00",
        "net_quantity": "100g",
        "manufacturer": "Acme Corp",
        "manufacturer_address": "123 Street, City",
        "country_of_origin": "India",
        "consumer_care_email": "support@acme.com",
        "consumer_care_phone": "1800-123-456",
        "mfg_date": "08/2026",
        "is_imported": False
    }
    result = validate_compliance(extracted)
    assert result.is_compliant is True
    assert result.compliance_score == 100
    assert result.status == "Compliant"
    # Ensure Importer Details is not even in evaluated fields
    field_names = [f.field_name for f in result.fields]
    assert "Importer Details" not in field_names

def test_all_fields_present_imported():
    extracted = {
        "mrp": "Rs. 99.00",
        "net_quantity": "100g",
        "manufacturer": "Acme Corp",
        "manufacturer_address": "123 Street, City",
        "country_of_origin": "India",
        "consumer_care_email": "support@acme.com",
        "consumer_care_phone": "1800-123-456",
        "mfg_date": "08/2026",
        "is_imported": True,
        "importer": "Global Importers Ltd"
    }
    result = validate_compliance(extracted)
    assert result.is_compliant is True
    assert result.compliance_score == 100
    assert result.status == "Compliant"
    field_names = [f.field_name for f in result.fields]
    assert "Importer Details" in field_names

def test_each_field_missing_individually_domestic():
    base = {
        "mrp": "Rs. 99.00",
        "net_quantity": "100g",
        "manufacturer": "Acme Corp",
        "manufacturer_address": "123 Street, City",
        "country_of_origin": "India",
        "consumer_care_email": "support@acme.com",
        "consumer_care_phone": "1800-123-456",
        "mfg_date": "08/2026",
        "is_imported": False
    }
    
    # 1. Missing MRP (Weight 25)
    mrp_missing = base.copy()
    mrp_missing.pop("mrp")
    res = validate_compliance(mrp_missing)
    # Total evaluated weight = 100. Missing = 25. Found = 75. Score = 75
    assert res.compliance_score == 75
    assert res.is_compliant is False
    assert res.status == "Non-Compliant"
    mrp_field = next(f for f in res.fields if f.field_name == "MRP")
    assert mrp_field.is_found is False
    assert mrp_field.violated_clause is not None

    # 2. Missing Net Quantity (Weight 25)
    net_qty_missing = base.copy()
    net_qty_missing.pop("net_quantity")
    res = validate_compliance(net_qty_missing)
    # Score = 75
    assert res.compliance_score == 75
    assert res.is_compliant is False

    # 3. Missing Manufacturer Name (Weight 8)
    mfg_name_missing = base.copy()
    mfg_name_missing.pop("manufacturer")
    res = validate_compliance(mfg_name_missing)
    # Total weight = 100. Missing = 8. Found = 92. Score = 92
    assert res.compliance_score == 92
    assert res.is_compliant is True

    # 4. Missing Manufacturer Address (Weight 7)
    mfg_addr_missing = base.copy()
    mfg_addr_missing.pop("manufacturer_address")
    res = validate_compliance(mfg_addr_missing)
    # Total weight = 100. Missing = 7. Found = 93. Score = 93
    assert res.compliance_score == 93
    assert res.is_compliant is True

    # 5. Missing Country of Origin (Weight 15)
    coo_missing = base.copy()
    coo_missing.pop("country_of_origin")
    res = validate_compliance(coo_missing)
    # Total weight = 100. Missing = 15. Found = 85. Score = 85
    assert res.compliance_score == 85
    assert res.is_compliant is False

    # 6. Missing Consumer Care Details (Weight 10, needs both gone since require_all=False)
    cc_missing = base.copy()
    cc_missing.pop("consumer_care_email")
    # One is still present
    res = validate_compliance(cc_missing)
    assert res.compliance_score == 100 # require_all = False, so 100
    
    # Both gone
    cc_both_missing = cc_missing.copy()
    cc_both_missing.pop("consumer_care_phone")
    res = validate_compliance(cc_both_missing)
    # Total weight = 100. Missing = 10. Found = 90. Score = 90
    assert res.compliance_score == 90
    assert res.is_compliant is True # 90 >= 90 threshold is compliant

    # 7. Missing Mfg Date (Weight 10)
    mfg_date_missing = base.copy()
    mfg_date_missing.pop("mfg_date")
    res = validate_compliance(mfg_date_missing)
    # Total weight = 100. Missing = 10. Found = 90. Score = 90
    assert res.compliance_score == 90
    assert res.is_compliant is True

def test_imported_missing_importer_details():
    # If imported product is missing importer details, score should drop 10 points
    extracted = {
        "mrp": "Rs. 99.00",
        "net_quantity": "100g",
        "manufacturer": "Acme Corp",
        "manufacturer_address": "123 Street, City",
        "country_of_origin": "India",
        "consumer_care_email": "support@acme.com",
        "consumer_care_phone": "1800-123-456",
        "mfg_date": "08/2026",
        "is_imported": True
        # importer is missing
    }
    result = validate_compliance(extracted)
    # Total weight = 110. Missing importer = 10. Found = 100. Score = 100/110 * 100 = 90
    assert result.compliance_score == 90
    assert result.is_compliant is True # 90 >= 90 threshold is compliant
    field_names = [f.field_name for f in result.fields]
    assert "Importer Details" in field_names
    importer_field = next(f for f in result.fields if f.field_name == "Importer Details")
    assert importer_field.is_found is False
    assert importer_field.violated_clause is not None

def test_multiple_fields_missing():
    # MRP (25) and Mfg Date (10) missing on domestic
    extracted = {
        "net_quantity": "100g",
        "manufacturer": "Acme Corp",
        "manufacturer_address": "123 Street, City",
        "country_of_origin": "India",
        "consumer_care_email": "support@acme.com",
        "is_imported": False
    }
    result = validate_compliance(extracted)
    # Missing: mrp (25), mfg_date (10). Found: net_quantity (25), manufacturer (8), manufacturer_address (7), country_of_origin (15), consumer_care (10) -> 65
    # Total weight = 100. Found = 65. Score = 65
    assert result.compliance_score == 65
    assert result.is_compliant is False

def test_empty_or_malformed_input():
    # Empty dictionary
    result = validate_compliance({})
    # Total weight = 90 (since not imported). Found = 0. Score = 0
    assert result.compliance_score == 0
    assert result.is_compliant is False
    
    # Values that are empty strings or None
    extracted = {
        "mrp": " ",
        "net_quantity": None,
        "manufacturer": "",
        "is_imported": "invalid_boolean_string" # will be evaluated as False
    }
    result = validate_compliance(extracted)
    assert result.compliance_score == 0
    assert result.is_compliant is False
