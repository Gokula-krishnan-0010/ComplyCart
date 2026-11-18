import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class AnalysisStep {
  final String title;
  final String description;

  const AnalysisStep({required this.title, required this.description});
}

class ProcessingOverlay extends StatefulWidget {
  final VoidCallback onComplete;
  final List<AnalysisStep> steps;
  final Future<void> Function() runAnalysis;
  final VoidCallback? onCancel;

  const ProcessingOverlay({
    super.key,
    required this.onComplete,
    required this.steps,
    required this.runAnalysis,
    this.onCancel,
  });

  @override
  State<ProcessingOverlay> createState() => _ProcessingOverlayState();
}

class _ProcessingOverlayState extends State<ProcessingOverlay> with TickerProviderStateMixin {
  int _currentStep = 0;
  int? _failedStep;
  String? _errorMessage;
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.steps.length,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 800),
      ),
    );

    _animations = _controllers.map((c) => CurvedAnimation(parent: c, curve: Curves.easeInOut)).toList();

    _startProcessing();
  }

  int _getErrorStep(dynamic error) {
    if (error is AnalysisException) {
      if (error.errorCode == 'SCRAPE_BLOCKED' || error.errorCode == 'SCRAPE_TIMEOUT') {
        return 0; // "Fetching product listing"
      }
      if (error.errorCode == 'EXTRACTION_FAILED') {
        return 1; // "Extracting label data"
      }
    }
    final str = error.toString();
    if (str.contains('SCRAPE_BLOCKED') || str.contains('SCRAPE_TIMEOUT')) {
      return 0;
    }
    if (str.contains('EXTRACTION_FAILED')) {
      return 1;
    }
    return 0; // Default fallback to step 0
  }

  Future<void> _startProcessing() async {
    setState(() {
      _currentStep = 0;
      _failedStep = null;
      _errorMessage = null;
    });
    for (var controller in _controllers) {
      controller.reset();
    }

    bool isDone = false;
    dynamic analysisError;

    // Start the analysis in the background
    widget.runAnalysis().then((_) {
      isDone = true;
    }).catchError((err) {
      isDone = true;
      analysisError = err;
    });

    for (int i = 0; i < widget.steps.length; i++) {
      if (!mounted) return;
      setState(() => _currentStep = i);

      // Bounded animation: wait for the step duration (e.g. 1.5s) unless future is completed.
      const stepDuration = Duration(milliseconds: 1500);
      const checkInterval = Duration(milliseconds: 100);
      int elapsed = 0;

      while (elapsed < stepDuration.inMilliseconds && !isDone) {
        await Future.delayed(checkInterval);
        elapsed += checkInterval.inMilliseconds;
      }

      if (analysisError != null) {
        final failedIdx = _getErrorStep(analysisError);
        setState(() {
          _failedStep = failedIdx;
          _currentStep = failedIdx;
          String cleanMsg = analysisError.toString();
          if (analysisError is AnalysisException) {
            cleanMsg = analysisError.message;
          } else if (cleanMsg.contains('AnalysisException:')) {
            cleanMsg = cleanMsg.split(':').last.trim();
          }
          _errorMessage = cleanMsg;
        });
        return;
      }

      if (mounted) {
        await _controllers[i].forward();
      }

      if (isDone && analysisError == null) {
        // Fast-forward remaining steps
        continue;
      }
    }

    if (analysisError != null) {
      final failedIdx = _getErrorStep(analysisError);
      setState(() {
        _failedStep = failedIdx;
        _currentStep = failedIdx;
        String cleanMsg = analysisError.toString();
        if (analysisError is AnalysisException) {
          cleanMsg = analysisError.message;
        } else if (cleanMsg.contains('AnalysisException:')) {
          cleanMsg = cleanMsg.split(':').last.trim();
        }
        _errorMessage = cleanMsg;
      });
      return;
    }

    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) widget.onComplete();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.medium,
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text('AI Analysis in Progress', style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          ...List.generate(widget.steps.length, (index) {
            return _buildStepItem(index);
          }),
          if (_failedStep != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _startProcessing();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      widget.onCancel?.call();
                    },
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildStepItem(int index) {
    final isCompleted = _currentStep > index || (_currentStep == index && _controllers[index].isCompleted);
    final isActive = _currentStep == index && _failedStep == null;
    final isUpcoming = _currentStep < index;
    final isFailed = _failedStep == index;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              _buildIndicator(index, isCompleted, isActive, isFailed),
              if (index < widget.steps.length - 1)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: isCompleted ? AppColors.success : (isFailed ? AppColors.error : AppColors.surfaceVariant),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.steps[index].title,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isFailed 
                          ? AppColors.error 
                          : (isUpcoming ? AppColors.textTertiary : AppColors.textPrimary),
                    ),
                  ),
                  if (isActive)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        widget.steps[index].description,
                        style: AppTextStyles.caption.copyWith(color: AppColors.primary),
                      ),
                    ),
                  if (isFailed)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _errorMessage ?? 'An error occurred during this step.',
                        style: AppTextStyles.caption.copyWith(color: AppColors.error),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(int index, bool isCompleted, bool isActive, bool isFailed) {
    if (isFailed) {
      return Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          color: AppColors.error,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.close, color: Colors.white, size: 16),
      );
    }

    if (isCompleted) {
      return ScaleTransition(
        scale: _animations[index],
        child: Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: AppColors.success,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, color: Colors.white, size: 16),
        ),
      );
    }

    if (isActive) {
      return SizedBox(
        width: 24,
        height: 24,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary.withOpacity(0.3)),
            ),
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.surfaceVariant, width: 2),
      ),
    );
  }
}
