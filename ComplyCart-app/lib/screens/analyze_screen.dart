import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/compliance_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/compliance_score_card.dart';
import '../widgets/analysis_widgets.dart';
import 'analysis_detail_screen.dart';

import '../widgets/processing_animation.dart';

class UrlAnalyzerView extends StatefulWidget {
  const UrlAnalyzerView({super.key});

  @override
  State<UrlAnalyzerView> createState() => _UrlAnalyzerViewState();
}

class _UrlAnalyzerViewState extends State<UrlAnalyzerView> {
  final TextEditingController _urlController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isProcessingInternal = false;

  final List<AnalysisStep> _analysisSteps = [
    const AnalysisStep(title: 'Fetching product listing', description: 'Accessing platform API...'),
    const AnalysisStep(title: 'Extracting label data', description: 'Identifying mandatory fields...'),
    const AnalysisStep(title: 'Running compliance checks', description: 'Cross-referencing legal rules...'),
    const AnalysisStep(title: 'Generating report', description: 'Finalizing scores and badges...'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ComplianceProvider>().refreshData();
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => context.read<ComplianceProvider>().refreshData(),
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Paste Product URL',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // URL Input Field - Optimized with Selector
            Selector<ComplianceProvider, bool>(
              selector: (_, p) => p.isLoading,
              builder: (context, isLoading, _) {
                return TextField(
                  controller: _urlController,
                  decoration: InputDecoration(
                    hintText: 'Amazon or Flipkart URL',
                    prefixIcon: const Icon(Icons.link),
                    fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
                  ),
                  enabled: !isLoading,
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // Analyze Button - Optimized with Selector
            Selector<ComplianceProvider, bool>(
              selector: (_, p) => p.isLoading,
              builder: (context, isLoading, _) {
                final isWorking = isLoading || _isProcessingInternal;
                
                return ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _urlController,
                  builder: (context, value, _) {
                    final isEmpty = value.text.trim().isEmpty;
                    return ElevatedButton.icon(
                      onPressed: isWorking || isEmpty
                        ? null 
                        : () {
                            setState(() => _isProcessingInternal = true);
                          },
                      icon: isWorking
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.search),
                      label: Text(isWorking ? 'Analyzing...' : 'Analyze URL'),
                    );
                  }
                );
              },
            ),
            
            const SizedBox(height: AppSpacing.xxl),
            
            // Quick Stats Row - Optimized with Selector
            Selector<ComplianceProvider, (int, int, int)>(
              selector: (_, p) => (p.totalScans, p.compliantCount, p.nonCompliantCount),
              builder: (context, stats, _) {
                return QuickStatsRow(
                  total: stats.$1,
                  compliant: stats.$2,
                  nonCompliant: stats.$3,
                );
              },
            ),
            
            // Error Display
            Consumer<ComplianceProvider>(
              builder: (context, provider, _) {
                if (provider.error == null || _isProcessingInternal) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.lg),
                  child: Text(
                    provider.error!,
                    style: const TextStyle(color: AppColors.error),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
            
            // Current Analysis Result or Processing Animation
            Consumer<ComplianceProvider>(
              builder: (context, provider, _) {
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: _isProcessingInternal
                      ? Padding(
                          key: const ValueKey('processing'),
                          padding: const EdgeInsets.only(top: AppSpacing.xxxl),
                          child: ProcessingOverlay(
                            steps: _analysisSteps,
                            runAnalysis: () => provider.analyzeUrl(_urlController.text.trim()),
                            onComplete: () {
                              setState(() => _isProcessingInternal = false);
                              _scrollToTop();
                            },
                            onCancel: () {
                              setState(() => _isProcessingInternal = false);
                            },
                          ),
                        )
                      : (provider.analysisResult == null
                          ? const SizedBox.shrink()
                        : Padding(
                            key: const ValueKey('result'),
                            padding: const EdgeInsets.only(top: AppSpacing.xxxl),
                            child: ComplianceScoreCard(result: provider.analysisResult!),
                          )),
              );
            },
          ),

          const SizedBox(height: AppSpacing.xxxl),
          
          // History or Guide Section
          Consumer<ComplianceProvider>(
            builder: (context, provider, _) {
              if (_isProcessingInternal) return const SizedBox.shrink();

              if (provider.history.isEmpty) {
                return const AnimatedEntry(index: 0, child: HowItWorksGuide());
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Row(
                      children: [
                        const Icon(Icons.history, size: 20, color: AppColors.textSecondary),
                        const SizedBox(width: AppSpacing.sm),
                        Text('Recent Analyses', style: AppTextStyles.h3),
                      ],
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: provider.history.length,
                    itemBuilder: (context, index) {
                      final record = provider.history[index];
                      return AnimatedEntry(
                        key: ValueKey(record.timestamp.toIso8601String()), // Help Flutter track the widget
                        index: index,
                        child: AnalysisHistoryCard(
                          record: record,
                          onTap: () {
                            Navigator.of(context).push(
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) =>
                                    AnalysisDetailScreen(analysisId: record.id),
                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                  var begin = const Offset(0.0, 0.05);
                                  var end = Offset.zero;
                                  var curve = Curves.easeOutCubic;
                                  var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                                  return SlideTransition(
                                    position: animation.drive(tween),
                                    child: FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.huge),
        ],
      ),
    ),
  );
}
}

class AnimatedEntry extends StatefulWidget {
  final Widget child;
  final int index;

  const AnimatedEntry({super.key, required this.child, required this.index});

  @override
  State<AnimatedEntry> createState() => _AnimatedEntryState();
}

class _AnimatedEntryState extends State<AnimatedEntry> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart));

    // Staggered entrance
    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
