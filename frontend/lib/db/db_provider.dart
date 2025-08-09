import 'dart:io';

import 'package:sportsin/models/achievement.dart';
import 'package:sportsin/models/camp_openning.dart';
import 'package:sportsin/models/chat_message.dart';
import 'package:sportsin/models/chat_room.dart';
import 'package:sportsin/models/comment_model.dart';
import 'package:sportsin/models/enums.dart';
import 'package:sportsin/models/post.dart';
import 'package:sportsin/models/tournament.dart';
import 'package:sportsin/models/tournament_participants.dart';
import 'package:sportsin/models/user.dart';
import 'package:sportsin/models/user_search_result.dart';
import 'package:sportsin/services/db/db_model.dart';
import 'package:sportsin/services/db/repositories/chat_repository.dart';
import 'package:sportsin/services/db/repositories/comment_repository.dart';
import 'package:sportsin/services/db/repositories/like_repository.dart';
import 'package:sportsin/services/db/repositories/search_repository.dart';
import 'package:sportsin/services/db/repositories/user_reporitory.dart';
import 'package:sportsin/services/db/repositories/post_repository.dart';
import 'package:sportsin/services/db/repositories/tournament_repository.dart';
import 'package:sportsin/services/db/repositories/acheivement_repository.dart';
import 'package:sportsin/services/db/repositories/camp_opening_repository.dart';

class DbProvider implements DbModel {
  static DbProvider? _instance;
  bool _isInitialized = false;

  // Repository instances
  late final UserRepository _userRepository;
  late final PostRepository _postRepository;
  late final TournamentRepository _tournamentRepository;
  late final AchievementRepository _achievementRepository;
  late final LikeRepository _likeRepository;
  late final CommentRepository _commentRepository;
  late final ChatRepository _chatRepository;
  late final CampOpeningRepository _campOpeningRepository;
  late final SearchRepository _searchRepository;

  DbProvider._() {
    _userRepository = UserRepository.instance;
    _postRepository = PostRepository.instance;
    _tournamentRepository = TournamentRepository.instance;
    _achievementRepository = AchievementRepository.instance;
    _likeRepository = LikeRepository.instance;
    _commentRepository = CommentRepository.instance;
    _chatRepository = ChatRepository.instance;
    _campOpeningRepository = CampOpeningRepository.instance;
    _searchRepository = SearchRepository.instance;
  }

  static DbProvider get instance {
    _instance ??= DbProvider._();
    return _instance!;
  }

  factory DbProvider() => instance;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      await _userRepository.getUser();
      _isInitialized = true;
    } catch (e) {
      _isInitialized = true;
    }
  }

  bool get isInitialized => _isInitialized;

  static void reset() {
    _instance?._userRepository.clearCache();
    _instance?._isInitialized = false;
    _instance = null;
  }

  User? get user => _userRepository.cachedUser;

  @override
  void updateCachedUser(User user) {
    _userRepository.updateCachedUser(user);
  }

  @override
  Future<T> createUser<T extends User>(T user) async {
    return await _userRepository.createUser(user);
  }

  @override
  Future<User?> getUser() async {
    return await _userRepository.getUser();
  }

  @override
  Future<T> updateUser<T extends User>(T user) async {
    return await _userRepository.updateUser(user);
  }

  @override
  Future<User?> getUserById(String uid) async {
    return await _userRepository.getUserById(uid);
  }

  @override
  User? get cashedUser => _userRepository.cachedUser;

  void clearCache() {
    _userRepository.clearCache();
  }

  Future<User?> refreshUserCache() async {
    return await _userRepository.refreshUserCache();
  }

  @override
  Future<Post> createPost(
      {required String content,
      List<String>? tags,
      required List<File> images}) async {
    return await _postRepository.createPost(
      content: content,
      tags: tags,
      images: images,
    );
  }

  @override
  Future<void> deletePost(String postId) async {
    return await _postRepository.deletePost(postId);
  }

  @override
  Future<List<Post>> getMyPosts({int? limit, int? offset}) async {
    return await _postRepository.getMyPosts(limit: limit, offset: offset);
  }

  @override
  Future<Post?> getPostById(String postId) async {
    return await _postRepository.getPostById(postId);
  }

  @override
  Future<List<Post>> getPostWithPagination(
      {String? userId, int? limit, int? offset}) async {
    return await _postRepository.getPostWithPagination(
      userId: userId,
      limit: limit,
      offset: offset,
    );
  }

  @override
  Future<Post> updatePost(
    Post post, {
    List<File>? newImages,
    bool replaceImages = false,
  }) async {
    return await _postRepository.updatePost(
      post,
      newImages: newImages,
      replaceImages: replaceImages,
    );
  }

  @override
  Future<Tournament> createTournament(Tournament tournament, File image) async {
    return await _tournamentRepository.createTournament(tournament, image);
  }

  @override
  Future<void> deleteTournament(String tournamentId) async {
    return await _tournamentRepository.deleteTournament(tournamentId);
  }

  @override
  Future<List<TournamentParticipants>> getMyParticipatedTournaments(
      {ParticipationStatus? status}) async {
    return await _tournamentRepository.getMyParticipatedTournaments(
      status: status,
    );
  }

  @override
  Future<Tournament?> getTournamentById(String tournamentId) async {
    return await _tournamentRepository.getTournamentById(tournamentId);
  }

  @override
  Future<List<TournamentParticipants>> getTournamentParticipants(
      String tournamentId,
      {String? status}) async {
    return await _tournamentRepository.getTournamentParticipants(
      tournamentId,
      status: status,
    );
  }

  @override
  Future<List<Tournament>> getTournaments(
      {String? hostId,
      String? sportId,
      String? status,
      int? page,
      int? limit}) async {
    return await _tournamentRepository.getTournaments(
      hostId: hostId,
      sportId: sportId,
      status: status,
      page: page,
      limit: limit,
    );
  }

  @override
  Future<String> joinTournament(String tournamentId) async {
    return await _tournamentRepository.joinTournament(tournamentId);
  }

  @override
  Future<String> leaveTournament(String tournamentId) async {
    return await _tournamentRepository.leaveTournament(tournamentId);
  }

  @override
  Future<Tournament> updateTournament(Tournament tournament) async {
    return await _tournamentRepository.updateTournament(tournament);
  }

  @override
  Future<String> updateTournamentParticipationStatus(
      {required String tournamentId,
      required String userId,
      required ParticipationStatus status}) async {
    return await _tournamentRepository.updateTournamentParticipationStatus(
      tournamentId: tournamentId,
      userId: userId,
      status: status,
    );
  }

  @override
  Future<Achievement> createAcheivement(Achievement acheivement) async {
    return await _achievementRepository.createAcheivement(acheivement);
  }

  @override
  Future<void> deleteAchievement(String achievementId) async {
    return await _achievementRepository.deleteAchievement(achievementId);
  }

  @override
  Future<void> deleteAchievementCertificate(String achievementId) async {
    return await _achievementRepository
        .deleteAchievementCertificate(achievementId);
  }

  @override
  Future<Achievement?> getAchievementById(String achievementId) async {
    return await _achievementRepository.getAchievementById(achievementId);
  }

  @override
  Future<List<Achievement>> getMyAchievements() async {
    return await _achievementRepository.getMyAchievements();
  }

  @override
  Future<Achievement> updateAchievement(Achievement achievement) async {
    return await _achievementRepository.updateAchievement(achievement);
  }

  @override
  Future<Map<String, String>> uploadAchievementCertificate(
      {required String achievementId, required File certificateFile}) async {
    return await _achievementRepository.uploadAchievementCertificate(
      achievementId: achievementId,
      certificateFile: certificateFile,
    );
  }

  @override
  Future<void> likePost(String postId) async {
    return await _likeRepository.likePost(postId);
  }

  @override
  Future<void> unlikePost(String postId) async {
    return await _likeRepository.unlikePost(postId);
  }

  @override
  Future<Comment> createComment(
      {required String postId,
      required String content,
      String? parentCommentId}) async {
    return await _commentRepository.createComment(
      postId: postId,
      content: content,
      parentCommentId: parentCommentId,
    );
  }

  @override
  Future<void> deleteComment(String commentId) async {
    return await _commentRepository.deleteComment(commentId);
  }

  @override
  Future<CommentResponse?> getCommentById(
      {required String commentId, int? replyLimit, int? replyOffset}) async {
    return await _commentRepository.getCommentById(
      commentId: commentId,
      replyLimit: replyLimit,
      replyOffset: replyOffset,
    );
  }

  @override
  Future<List<CommentResponse>> getCommentsByPostId(
      {required String postId, int? limit, int? offset}) async {
    return await _commentRepository.getCommentsByPostId(
      postId: postId,
      limit: limit,
      offset: offset,
    );
  }

  @override
  Future<void> updateComment(
      {required String commentId, required String content}) async {
    return await _commentRepository.updateComment(
      commentId: commentId,
      content: content,
    );
  }

  @override
  Future<void> connectToChat() async {
    return await _chatRepository.connectToChat();
  }

  @override
  Future<void> disconnectFromChat() async {
    return await _chatRepository.disconnectFromChat();
  }

  @override
  Future<List<ChatRoom>> getChatRooms() async {
    return await _chatRepository.getChatRooms();
  }

  @override
  Future<List<ChatMessage>> getMessagesForRoom(String roomId,
      {int? limit, int? offset}) async {
    return await _chatRepository.getMessagesForRoom(roomId,
        limit: limit, offset: offset);
  }

  @override
  Future<void> markRoomAsRead(String roomId) async {
    return await _chatRepository.markRoomAsRead(roomId);
  }

  @override
  Future<void> sendMessage(
      {required String recipientId, required String content}) async {
    return await _chatRepository.sendMessage(
        recipientId: recipientId, content: content);
  }

  @override
  Stream<ChatMessage> get messagesStream => _chatRepository.messagesStream;

  @override
  Future<void> applyToOpening(String openingId) async {
    return await _campOpeningRepository.applyToOpening(openingId);
  }

  @override
  Future<CampOpenning> createOpening(CampOpenning opening) async {
    return await _campOpeningRepository.createOpening(opening);
  }

  @override
  Future<void> deleteOpening(String openingId) async {
    return await _campOpeningRepository.deleteOpening(openingId);
  }

  @override
  Future<List<CampOpenning>> getMyOpenings({int? limit, int? offset}) async {
    return await _campOpeningRepository.getMyOpenings(
      limit: limit,
      offset: offset,
    );
  }

  @override
  Future<List> getOpeningApplicants(String openingId) async {
    return await _campOpeningRepository.getOpeningApplicants(openingId);
  }

  @override
  Future<CampOpenning?> getOpeningById(String openingId) async {
    return await _campOpeningRepository.getOpeningById(openingId);
  }

  @override
  Future<List<CampOpenning>> getOpenings(
      {int? limit,
      int? offset,
      String? recruiterId,
      String? sportId,
      String? country,
      bool? applied}) async {
    return await _campOpeningRepository.getOpenings(
      limit: limit,
      offset: offset,
      recruiterId: recruiterId,
      sportId: sportId,
      country: country,
      applied: applied,
    );
  }

  @override
  Future<void> updateApplicationStatus(
      {required String openingId,
      required String applicationId,
      required OpeningStatus status}) async {
    return await _campOpeningRepository.updateApplicationStatus(
      openingId: openingId,
      applicationId: applicationId,
      status: status,
    );
  }

  @override
  Future<CampOpenning> updateOpening(CampOpenning opening) async {
    return await _campOpeningRepository.updateOpening(opening);
  }

  @override
  Future<CampOpenning> updateOpeningStatus(
      {required String openingId, required OpeningStatus status}) async {
    return await _campOpeningRepository.updateOpeningStatus(
      openingId: openingId,
      status: status,
    );
  }

  @override
  Future<void> withdrawApplication(
      String openingId, String applicationId) async {
    return await _campOpeningRepository.withdrawApplication(
        openingId, applicationId);
  }

  @override
  Future<String> getMyReferralCode() async {
    return await _userRepository.getMyReferralCode();
  }

  @override
  Future<List<UserSearchResult>> searchUsers(String query) async {
    return await _searchRepository.searchUsers(query);
  }
}
