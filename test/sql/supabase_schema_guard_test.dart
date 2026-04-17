import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'supabase full setup SQL includes critical profile + ML guards',
    () async {
      final file = File('docs/sql/supabase_full_setup.sql');
      expect(
        await file.exists(),
        isTrue,
        reason: 'Missing unified SQL setup file',
      );

      final sql = await file.readAsString();

      expect(sql, contains('create table if not exists public.profiles'));
      expect(sql, contains('height_cm int'));
      expect(sql, contains('profiles_height_cm_check'));

      expect(
        sql,
        contains('create table if not exists public.outfit_feedback_events'),
      );
      expect(
        sql,
        contains('create table if not exists public.outfit_ml_scores'),
      );
      expect(
        sql,
        contains('create table if not exists public.outfit_llm_scores'),
      );
      expect(
        sql,
        contains('create table if not exists public.outfit_llm_details'),
      );

      expect(sql, contains('create policy "profiles_select_own"'));
      expect(sql, contains('create policy "outfit_feedback_insert_own"'));
      expect(sql, contains('create policy "outfit_ml_scores_select_own"'));
      expect(sql, contains('create policy "outfit_llm_scores_select_own"'));
      expect(sql, contains('create policy "outfit_llm_details_select_own"'));
    },
  );
}
