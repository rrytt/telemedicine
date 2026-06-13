import '../../core/supabase/supabase_service.dart';


class DoctorPostsService {
  DoctorPostsService._();

  static Future<List<Map<String, dynamic>>> fetchDoctorPosts({
    int limit = 30,
  }) async {
    final response = await SupabaseService.client
        .from('doctor_posts')
        .select('''
          id,
          doctor_id,
          title,
          body,
          created_at,
          doctor:doctor_id(full_name, avatar_url)
        ''')
        .order('created_at', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(response as List<dynamic>);
  }

  static Future<List<Map<String, dynamic>>> fetchPostComments({
    required String postId,
    int limit = 50,
  }) async {
    final response = await SupabaseService.client
        .from('post_comments')
        .select('''
          id,
          post_id,
          user_id,
          body,
          created_at,
          user:profiles(id, full_name, avatar_url)
        ''')
        .eq('post_id', postId)
        .order('created_at', ascending: true)
        .limit(limit);

    return List<Map<String, dynamic>>.from(response as List<dynamic>);
  }


  static Future<int> fetchPostLikesCount(String postId) async {
    final response = await SupabaseService.client
        .from('post_likes')
        .select('id')
        .eq('post_id', postId);

    return response.length;
  }

  static Future<bool> toggleLike(
    String postId, {
    required bool currentlyLiked,
  }) async {

    final user = SupabaseService.client.auth.currentUser;
    if (user == null) {
      throw StateError('User not authenticated');
    }

    if (currentlyLiked) {
      await SupabaseService.client
          .from('post_likes')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', user.id);
      return false;
    }

    await SupabaseService.client.from('post_likes').insert({
      'post_id': postId,
      'user_id': user.id,
    });

    return true;
  }

  static Future<void> createPost({
    required String title,
    required String body,
  }) async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) {
      throw StateError('User not authenticated');
    }

    await SupabaseService.client.from('doctor_posts').insert({
      'doctor_id': user.id,
      'title': title,
      'body': body,
    });
  }

  static Future<List<Map<String, dynamic>>> fetchMyPosts() async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) {
      throw StateError('User not authenticated');
    }

    final response = await SupabaseService.client
        .from('doctor_posts')
        .select('''
          id,
          doctor_id,
          title,
          body,
          created_at,
          doctor:doctor_id(full_name, avatar_url)
        ''')
        .eq('doctor_id', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response as List<dynamic>);
  }

  static Future<void> updatePost({
    required String postId,
    required String title,
    required String body,
  }) async {
    await SupabaseService.client.from('doctor_posts').update({
      'title': title,
      'body': body,
    }).eq('id', postId);
  }

  static Future<void> deletePost(String postId) async {
    await SupabaseService.client.from('doctor_posts').delete().eq('id', postId);
  }

  static Future<bool> checkIfUserLiked(String postId) async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) {
      return false;
    }

    final response = await SupabaseService.client
        .from('post_likes')
        .select('id')
        .eq('post_id', postId)
        .eq('user_id', user.id)
        .maybeSingle();

    return response != null;
  }
}

