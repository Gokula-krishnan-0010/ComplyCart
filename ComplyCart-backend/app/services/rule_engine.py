import os
import json
from typing import List, Optional, Any
from pydantic import BaseModel

class ComplianceField(BaseModel):
    field_name: str
    is_found: bool
    violated_clause: Optional[str] = None
    extracted_value: Optional[str] = None

class ComplianceResult(BaseModel):
    is_compliant: bool
    compliance_score: int
    status: str
    fields: List[ComplianceField]

# Load compliance rules JSON at startup
RULES_FILE_PATH = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "core",
    "compliance_rules.json"
)

try:
    with open(RULES_FILE_PATH, "r", encoding="utf-8") as f:
        COMPLIANCE_RULES_CONFIG = json.load(f)
except Exception as e:
    # Fallback default rules if loading fails for any reason
    COMPLIANCE_RULES_CONFIG = {
        "rules": [
            {
                "field_name": "MRP",
                "keys": ["mrp"],
                "weight": 25,
                "violated_clause": "Maximum Retail Price (MRP) must be clearly declared on the package under Legal Metrology Rules."
            },
            {
                "field_name": "Net Quantity",
                "keys": ["net_quantity"],
                "weight": 25,
                "violated_clause": "Net quantity of the commodity contained in the package must be declared under Legal Metrology Rules."
            },
            {
                "field_name": "Manufacturer Name",
                "keys": ["manufacturer"],
                "weight": 8,
                "violated_clause": "Name of the manufacturer must be declared on the package."
            },
            {
                "field_name": "Manufacturer Address",
                "keys": ["manufacturer_address"],
                "weight": 7,
                "violated_clause": "Complete address of the manufacturer must be declared on the package."
            },
            {
                "field_name": "Country of Origin",
                "keys": ["country_of_origin"],
                "weight": 15,
                "violated_clause": "Country of origin of the product must be specified for consumer awareness."
            },
            {
                "field_name": "Consumer Care Details",
                "keys": ["consumer_care_email", "consumer_care_phone"],
                "require_all": False,
                "weight": 10,
                "violated_clause": "Consumer care details (email and/or phone) must be provided."
            },
            {
                "field_name": "Date of Manufacture/Import",
                "keys": ["mfg_date"],
                "weight": 10,
                "violated_clause": "Month and year of manufacture or import must be declared on the package."
            },
            {
                "field_name": "Importer Details",
                "keys": ["importer"],
                "weight": 10,
                "conditional_on": "is_imported",
                "violated_clause": "Name and address of the importer must be declared for imported commodities."
            }
        ],
        "compliance_threshold": 90
    }

def _is_value_present(val: Any) -> bool:
    if val is None:
        return False
    if isinstance(val, str):
        return len(val.strip()) > 0
    if isinstance(val, (list, dict, set)):
        return len(val) > 0
    return True

def validate_compliance(extracted_fields: dict) -> ComplianceResult:
    """
    Validates the product compliance against Legal Metrology rules config.
    Pure function - no DB/API calls.
    """
    fields_list = []
    total_weight = 0
    found_weight = 0
    
    rules = COMPLIANCE_RULES_CONFIG.get("rules", [])
    threshold = COMPLIANCE_RULES_CONFIG.get("compliance_threshold", 90)
    
    for rule in rules:
        conditional_on = rule.get("conditional_on")
        if conditional_on:
            # If the conditional field is not present or False, skip this rule
            is_conditional_active = False
            cond_val = extracted_fields.get(conditional_on)
            if isinstance(cond_val, bool):
                is_conditional_active = cond_val
            elif cond_val is not None:
                is_conditional_active = str(cond_val).lower() in ("true", "1", "yes")
            
            if not is_conditional_active:
                continue
        
        weight = rule.get("weight", 0)
        total_weight += weight
        
        keys = rule.get("keys", [])
        require_all = rule.get("require_all", True)
        
        if require_all:
            is_found = len(keys) > 0 and all(_is_value_present(extracted_fields.get(k)) for k in keys)
        else:
            is_found = any(_is_value_present(extracted_fields.get(k)) for k in keys)
            
        if is_found:
            found_weight += weight
            
            # Extract and format the actual found value(s)
            extracted_value = None
            vals = []
            for k in keys:
                val = extracted_fields.get(k)
                if _is_value_present(val):
                    vals.append(str(val))
            if vals:
                if rule["field_name"] == "Consumer Care Details":
                    email = extracted_fields.get("consumer_care_email")
                    phone = extracted_fields.get("consumer_care_phone")
                    if email and phone:
                        extracted_value = f"Email: {email}, Phone: {phone}"
                    elif email:
                        extracted_value = f"Email: {email}"
                    elif phone:
                        extracted_value = f"Phone: {phone}"
                else:
                    extracted_value = " / ".join(vals)
            
            fields_list.append(ComplianceField(
                field_name=rule["field_name"],
                is_found=True,
                extracted_value=extracted_value
            ))
        else:
            fields_list.append(ComplianceField(
                field_name=rule["field_name"],
                is_found=False,
                violated_clause=rule.get("violated_clause")
            ))
            
    if total_weight > 0:
        compliance_score = int((found_weight / total_weight) * 100)
    else:
        compliance_score = 100
        
    status = "Compliant" if compliance_score >= threshold else "Non-Compliant"
    is_compliant = status == "Compliant"
    
    return ComplianceResult(
        is_compliant=is_compliant,
        compliance_score=compliance_score,
        status=status,
        fields=fields_list
    )
