import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../providers/data_providers.dart';

class WriteReviewScreen extends ConsumerStatefulWidget {
  final String bookingId;
  final String barberId;
  final String? barberName;

  const WriteReviewScreen({
    super.key,
    required this.bookingId,
    required this.barberId,
    this.barberName,
  });

  @override
  ConsumerState<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends ConsumerState<WriteReviewScreen> {
  int _rating = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DCTheme.background,
      appBar: AppBar(
        title: const Text('Leave a Review'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            _buildRatingSelector(),
            const SizedBox(height: 32),
            _buildCommentField(),
            const SizedBox(height: 40),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: DCTheme.surface,
              border: Border.all(color: DCTheme.primary, width: 2),
            ),
            child: const Icon(
              Icons.content_cut,
              color: DCTheme.textMuted,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'How was your experience with',
            style: TextStyle(color: DCTheme.textMuted, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            widget.barberName ?? 'your barber',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: DCTheme.text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rating',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: DCTheme.text,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final starNumber = index + 1;
            final isSelected = starNumber <= _rating;
            return GestureDetector(
              onTap: () => setState(() => _rating = starNumber),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  isSelected ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 44,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            _getRatingLabel(),
            style: TextStyle(
              color: _rating > 0 ? DCTheme.text : DCTheme.textMuted,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  String _getRatingLabel() {
    switch (_rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent!';
      default:
        return 'Tap to rate';
    }
  }

  Widget _buildCommentField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Comment (Optional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: DCTheme.text,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _commentController,
          maxLines: 5,
          maxLength: 500,
          style: const TextStyle(color: DCTheme.text),
          decoration: InputDecoration(
            hintText: 'Share your experience...',
            hintStyle: const TextStyle(color: DCTheme.textMuted),
            filled: true,
            fillColor: DCTheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            counterStyle: const TextStyle(color: DCTheme.textMuted),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _rating > 0 && !_isSubmitting ? _submitReview : null,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          disabledBackgroundColor: DCTheme.surfaceSecondary,
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Submit Review',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  Future<void> _submitReview() async {
    setState(() => _isSubmitting = true);

    try {
      final service = ref.read(reviewServiceProvider);
      final review = await service.createReview(
        bookingId: widget.bookingId,
        barberId: widget.barberId,
        rating: _rating,
        comment: _commentController.text.trim().isNotEmpty
            ? _commentController.text.trim()
            : null,
      );

      if (!mounted) return;

      if (review != null) {
        // Invalidate review providers
        ref.invalidate(reviewsProvider(widget.barberId));
        ref.invalidate(ratingStatsProvider(widget.barberId));
        ref.invalidate(myReviewsProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review submitted successfully!'),
            backgroundColor: DCTheme.success,
          ),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit review. Please try again.'),
            backgroundColor: DCTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
