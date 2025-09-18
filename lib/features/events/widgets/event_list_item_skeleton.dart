import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class EventListItemSkeleton extends StatelessWidget {
  const EventListItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final imageHeight = MediaQuery.of(context).size.width * 0.56;
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: imageHeight,
            color: Colors.grey,
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 140,
                  height: 12,
                  color: Colors.grey,
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 18,
                  color: Colors.grey,
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 14,
                  color: Colors.grey,
                ),
                const SizedBox(height: 12),
                Container(
                  width: 200,
                  height: 14,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
