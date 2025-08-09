import 'dart:io';

import 'package:sportsin/models/models.dart';

abstract class DbModel {
  // user
  Future<T> createUser<T extends User>(T user);

  Future<User?> getUserById(String uid);

  Future<User?> getUser();

  Future<T> updateUser<T extends User>(T user);

  User? get cashedUser;

  void updateCachedUser(User user);

  // posts
  Future<Post> createPost({
    required String content,
    List<String>? tags,
    required List<File> images,
  });

  Future<Post?> getPostById(String postId);

  Future<List<Post>> getPostWithPagination({
    String? userId,
    int? limit,
    int? offset,
  });

  Future<Post> updatePost(Post post);

  Future<void> deletePost(String postId);

  Future<List<Post>> getMyPosts({
    int? limit,
    int? offset,
  });

  // tournaments
  Future<Tournament> createTournament(Tournament tournament, File image);

  Future<Tournament?> getTournamentById(String tournamentId);

  Future<List<Tournament>> getTournaments({
    String? hostId,
    String? sportId,
    String? status,
    int? page,
    int? limit,
  });
  Future<String> joinTournament(String tournamentId);

  Future<String> leaveTournament(String tournamentId);

  Future<List<TournamentParticipants>> getTournamentParticipants(
      String tournamentId,
      {String? status});

  Future<String> updateTournamentParticipationStatus({
    required String tournamentId,
    required String userId,
    required ParticipationStatus status,
  });

  Future<List<TournamentParticipants>> getMyParticipatedTournaments(
      {ParticipationStatus? status});

  Future<Tournament> updateTournament(Tournament tournament);

  Future<void> deleteTournament(String tournamentId);

  // acheivements
  Future<Achievement> createAcheivement(Achievement acheivement);

  Future<Achievement?> getAchievementById(String achievementId);

  Future<List<Achievement>> getMyAchievements();

  Future<Achievement> updateAchievement(Achievement achievement);

  Future<Map<String, String>> uploadAchievementCertificate({
    required String achievementId,
    required File certificateFile,
  });

  Future<void> deleteAchievementCertificate(String achievementId);

  Future<void> deleteAchievement(String achievementId);

  // like
  Future<void> likePost(String postId);
  Future<void> unlikePost(String postId);

  // comments
  Future<Comment> createComment({
    required String postId,
    required String content,
    String? parentCommentId,
  });

  Future<List<CommentResponse>> getCommentsByPostId({
    required String postId,
    int? limit,
    int? offset,
  });

  Future<CommentResponse?> getCommentById({
    required String commentId,
    int? replyLimit,
    int? replyOffset,
  });

  Future<void> updateComment({
    required String commentId,
    required String content,
  });

  Future<void> deleteComment(String commentId);

  // chat
  Future<void> connectToChat();

  Future<void> disconnectFromChat();

  Stream<ChatMessage> get messagesStream;

  Future<void> sendMessage({
    required String recipientId,
    required String content,
  });

  Future<List<ChatRoom>> getChatRooms();

  Future<List<ChatMessage>> getMessagesForRoom(
    String roomId, {
    int? limit,
    int? offset,
  });

  Future<void> markRoomAsRead(String roomId);

  // camp openings
  Future<CampOpenning> createOpening(CampOpenning opening);

  Future<CampOpenning?> getOpeningById(String openingId);

  Future<List<CampOpenning>> getOpenings({
    int? limit,
    int? offset,
    String? recruiterId,
    String? sportId,
    String? country,
    bool? applied,
  });

  Future<List<CampOpenning>> getMyOpenings({int? limit, int? offset});

  Future<CampOpenning> updateOpening(CampOpenning opening);

  Future<CampOpenning> updateOpeningStatus(
      {required String openingId, required OpeningStatus status});

  Future<void> deleteOpening(String openingId);

  Future<void> applyToOpening(String openingId);

  Future<void> withdrawApplication(String openingId, String applicationId);

  Future<List<dynamic>> getOpeningApplicants(String openingId);

  Future<void> updateApplicationStatus({
    required String openingId,
    required String applicationId,
    required OpeningStatus status,
  });

  // referral code
  Future<String> getMyReferralCode();

  // search
  Future<List<UserSearchResult>> searchUsers(String query);
}
