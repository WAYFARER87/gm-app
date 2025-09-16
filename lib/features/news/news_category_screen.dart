import 'package:flutter/material.dart';

import 'models/news_category.dart';
import 'news_list.dart';

class NewsCategoryScreen extends StatelessWidget {
  const NewsCategoryScreen({super.key, required this.category});

  final NewsCategory category;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: category.rubrics.length + 1,
      child: Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: Text(category.name),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              const Tab(text: 'Все'),
              for (final rubric in category.rubrics) Tab(text: rubric.name),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            NewsList(categoryId: category.id),
            for (final rubric in category.rubrics)
              NewsList(categoryId: rubric.id),
          ],
        ),
      ),
    );
  }
}
