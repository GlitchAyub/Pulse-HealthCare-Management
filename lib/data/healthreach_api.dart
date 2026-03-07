import 'package:http/http.dart' as http;
import '../core/api_client.dart';
import '../core/session_store.dart';

class HealthReachApi {
  HealthReachApi({SessionStore? sessionStore, ApiClient? client})
      : _client = client ?? ApiClient(sessionStore: sessionStore);
  final ApiClient _client;

  // Auth
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final data = await _client.postJson(
      '/api/login',
      body: {'email': email, 'password': password},
    );
    return _asMap(data);
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
  }) async {
    final data = await _client.postJson(
      '/api/register',
      body: {
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        'role': role,
      },
    );
    return _asMap(data);
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    final data = await _client.getJson('/api/auth/user');
    return _asMap(data);
  }

  Future<void> logout() async {
    await _client.getJson('/api/logout');
  }

  // Invitations
  Future<Map<String, dynamic>> getInvitationByToken(String token) async {
    final data = await _client.getJson('/api/invitations/token/$token');
    return _asMap(data);
  }

  Future<Map<String, dynamic>> acceptInvitation(String token) async {
    final data = await _client.postJson('/api/invitations/token/$token/accept');
    return _asMap(data);
  }

  Future<List<dynamic>> getInvitations() async {
    final data = await _client.getJson('/api/invitations');
    return _asList(data);
  }

  Future<List<dynamic>> getMyPendingInvitations() async {
    final data = await _client.getJson('/api/invitations/my-pending');
    if (data is Map) {
      return _asList(data['invitations']);
    }
    return _asList(data);
  }

  Future<Map<String, dynamic>> createInvitation({
    required String email,
    String? firstName,
    String? lastName,
    required String role,
  }) async {
    final data = await _client.postJson(
      '/api/invitations',
      body: {
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'role': role,
      },
    );
    return _asMap(data);
  }

  Future<Map<String, dynamic>> resendInvitation(String invitationId) async {
    final data =
        await _client.postJson('/api/invitations/$invitationId/resend');
    return _asMap(data);
  }

  Future<Map<String, dynamic>> deleteInvitation(String invitationId) async {
    final data = await _client.deleteJson('/api/invitations/$invitationId');
    return _asMap(data);
  }

  // Notifications
  Future<List<dynamic>> getNotifications({bool? unreadOnly, int? limit}) async {
    final data = await _client.getJson(
      '/api/notifications',
      query: _query({
        'unreadOnly': unreadOnly,
        'limit': limit,
      }),
    );
    return _asListWithKeys(data, const ['notifications', 'data', 'items']);
  }

  Future<Map<String, dynamic>> getUnreadNotificationCount() async {
    final data = await _client.getJson('/api/notifications/unread-count');
    return _asMap(data);
  }

  Future<Map<String, dynamic>> markNotificationRead(String id) async {
    final data = await _client.patchJson('/api/notifications/$id/read');
    return _asMap(data);
  }

  Future<Map<String, dynamic>> markAllNotificationsRead() async {
    final data = await _client.postJson('/api/notifications/mark-all-read');
    return _asMap(data);
  }

  // Dashboard
  Future<Map<String, dynamic>> getMyOrganization() async {
    final data = await _client.getJson('/api/my-organization');
    return _asMap(data);
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    final data = await _client.getJson('/api/dashboard/stats');
    return _asMap(data);
  }

  Future<Map<String, dynamic>> getInventoryStats() async {
    final data = await _client.getJson('/api/inventory-stats');
    return _asMap(data);
  }

  // Appointment Requests
  Future<List<dynamic>> getAppointmentRequests({String? status}) async {
    final data = await _client.getJson(
      '/api/appointment-requests',
      query: _query({'status': status}),
    );
    return _asListWithKeys(data, const [
      'requests',
      'appointmentRequests',
      'appointment_requests',
      'data',
      'items',
    ]);
  }

  Future<Map<String, dynamic>> createAppointmentRequest({
    required String requestType,
    required String visitMode,
    String? preferredDate,
    String? preferredTimeSlot,
    required String reason,
    required String urgency,
  }) async {
    final data = await _client.postJson(
      '/api/appointment-requests',
      body: {
        'requestType': requestType,
        'visitMode': visitMode,
        'preferredDate': preferredDate,
        'preferredTimeSlot': preferredTimeSlot,
        'reason': reason,
        'urgency': urgency,
      },
    );
    return _asMap(data);
  }

  Future<Map<String, dynamic>> updateAppointmentRequest(
    String id, {
    required Map<String, dynamic> payload,
  }) async {
    final data = await _client.patchJson(
      '/api/appointment-requests/$id',
      body: payload,
    );
    return _asMap(data);
  }

  Future<Map<String, dynamic>> deleteAppointmentRequest(String id) async {
    final data = await _client.deleteJson('/api/appointment-requests/$id');
    return _asMap(data);
  }

  // Patients
  Future<List<dynamic>> getPatients({
    String? search,
    int? limit,
    int? offset,
    bool? filterCritical,
  }) async {
    final data = await _client.getJson(
      '/api/patients',
      query: _query({
        'search': search,
        'limit': limit,
        'offset': offset,
        'filterCritical': filterCritical,
      }),
    );
    return _asListWithKeys(data, const ['patients', 'data', 'items']);
  }

  Future<Map<String, dynamic>> createPatient(
      Map<String, dynamic> payload) async {
    final data = await _client.postJson('/api/patients', body: payload);
    return _asMap(data);
  }

  // Visits
  Future<List<dynamic>> getVisits({String? patientId, int? limit}) async {
    final data = await _client.getJson(
      '/api/visits',
      query: _query({'patientId': patientId, 'limit': limit}),
    );
    return _asListWithKeys(data, const ['visits', 'data', 'items']);
  }

  Future<List<dynamic>> getMyVisits({int? limit}) async {
    try {
      return await getVisits(limit: limit);
    } on ApiException catch (error) {
      if (!_isPatientIdRequiredError(error) && !_isAccessRestricted(error)) {
        rethrow;
      }
    }

    final user = await getCurrentUser();
    final patientId = _resolvePatientIdentifier(user);
    if (patientId == null || patientId.isEmpty) {
      return <dynamic>[];
    }

    try {
      return await getVisits(patientId: patientId, limit: limit);
    } on ApiException catch (error) {
      if (_isAccessRestricted(error) || _isEndpointMissing(error)) {
        return <dynamic>[];
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createVisit(Map<String, dynamic> payload) async {
    final data = await _client.postJson('/api/visits', body: payload);
    return _asMap(data);
  }

  Future<Map<String, dynamic>> updateVisit(
    String id,
    Map<String, dynamic> payload,
  ) async {
    final data = await _client.patchJson('/api/visits/$id', body: payload);
    return _asMap(data);
  }

  // Lab Tests
  Future<List<dynamic>> getLabTests({String? patientId}) async {
    final data = await _client.getJson(
      '/api/lab-tests',
      query: _query({'patientId': patientId}),
    );
    return _asList(data);
  }

  // Imaging
  Future<List<dynamic>> getImagingReports({String? patientId}) async {
    final data = await _client.getJson(
      '/api/imaging-reports',
      query: _query({'patientId': patientId}),
    );
    return _asList(data);
  }

  // Medications
  Future<List<dynamic>> getMedications({String? patientId}) async {
    final data = await _client.getJson(
      '/api/medications',
      query: _query({'patientId': patientId}),
    );
    return _asListWithKeys(data, const ['medications', 'data', 'items']);
  }

  Future<Map<String, dynamic>> createMedication(
      Map<String, dynamic> payload) async {
    final data = await _client.postJson('/api/medications', body: payload);
    return _asMap(data);
  }

  Future<Map<String, dynamic>> updateMedication(
    String id,
    Map<String, dynamic> payload,
  ) async {
    final data = await _client.patchJson('/api/medications/$id', body: payload);
    return _asMap(data);
  }

  Future<List<dynamic>> getMedicationAdherence({
    required String medicationId,
    String? date,
  }) async {
    final data = await _client.getJson(
      '/api/medication-adherence',
      query: _query({'medicationId': medicationId, 'date': date}),
    );
    return _asList(data);
  }

  Future<Map<String, dynamic>> createMedicationAdherence(
      Map<String, dynamic> payload) async {
    final data =
        await _client.postJson('/api/medication-adherence', body: payload);
    return _asMap(data);
  }

  Future<Map<String, dynamic>> updateMedicationAdherence(
    String id,
    Map<String, dynamic> payload,
  ) async {
    final data =
        await _client.patchJson('/api/medication-adherence/$id', body: payload);
    return _asMap(data);
  }

  Future<List<dynamic>> getMyMedications() async {
    try {
      final data = await _client.getJson('/api/medications/my');
      return _asListWithKeys(data, const ['medications', 'data', 'items']);
    } on ApiException catch (error) {
      if (!_isEndpointMissing(error) && !_isAccessRestricted(error)) rethrow;
    }

    try {
      final data = await _client.getJson('/api/medications');
      final medications =
          _asListWithKeys(data, const ['medications', 'data', 'items']);
      if (medications.isNotEmpty) return medications;
    } on ApiException catch (error) {
      if (!_isPatientIdRequiredError(error) && !_isAccessRestricted(error)) {
        rethrow;
      }
    }

    final user = await getCurrentUser();
    final patientId = _resolvePatientIdentifier(user);
    if (patientId == null || patientId.isEmpty) {
      return <dynamic>[];
    }

    try {
      final data = await _client.getJson(
        '/api/medications',
        query: _query({'patientId': patientId}),
      );
      return _asListWithKeys(data, const ['medications', 'data', 'items']);
    } on ApiException catch (error) {
      if (_isAccessRestricted(error) || _isEndpointMissing(error)) {
        return <dynamic>[];
      }
      rethrow;
    }
  }

  // Consultations
  Future<List<dynamic>> getConsultations({
    bool? upcoming,
    String? patientId,
  }) async {
    final data = await _client.getJson(
      '/api/consultations',
      query: _query({
        'upcoming': upcoming,
        'patientId': patientId,
      }),
    );
    return _asListWithKeys(data, const ['consultations', 'data', 'items']);
  }

  Future<List<dynamic>> getMyConsultations({bool? upcoming}) async {
    try {
      return await getConsultations(upcoming: upcoming);
    } on ApiException catch (error) {
      if (!_isPatientIdRequiredError(error) && !_isAccessRestricted(error)) {
        rethrow;
      }
    }

    final user = await getCurrentUser();
    final patientId = _resolvePatientIdentifier(user);
    if (patientId == null || patientId.isEmpty) {
      return <dynamic>[];
    }

    try {
      return await getConsultations(upcoming: upcoming, patientId: patientId);
    } on ApiException catch (error) {
      if (_isAccessRestricted(error) || _isEndpointMissing(error)) {
        return <dynamic>[];
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createConsultation(
      Map<String, dynamic> payload) async {
    final data = await _client.postJson('/api/consultations', body: payload);
    return _asMap(data);
  }

  Future<Map<String, dynamic>> updateConsultation(
    String id,
    Map<String, dynamic> payload,
  ) async {
    final data =
        await _client.patchJson('/api/consultations/$id', body: payload);
    return _asMap(data);
  }

  Future<List<dynamic>> getConsultationFiles(String id) async {
    final data = await _client.getJson('/api/consultations/$id/files');
    return _asList(data);
  }

  Future<Map<String, dynamic>> uploadConsultationFile({
    required String consultationId,
    required http.MultipartFile file,
    required Map<String, String> fields,
  }) async {
    final data = await _client.postMultipart(
      '/api/consultations/$consultationId/files',
      file: file,
      fields: fields,
    );
    return _asMap(data);
  }

  Future<Map<String, dynamic>> deleteConsultationFile({
    required String consultationId,
    required String fileId,
  }) async {
    final data = await _client
        .deleteJson('/api/consultations/$consultationId/files/$fileId');
    return _asMap(data);
  }

  // Education Resources
  Future<List<dynamic>> getHealthResources({
    String? search,
    String? category,
  }) async {
    final data = await _client.getJson(
      '/api/health-resources',
      query: _query({'search': search, 'category': category}),
    );
    return _asListWithKeys(data, const [
      'resources',
      'healthResources',
      'health_resources',
      'data',
      'items',
    ]);
  }

  Future<Map<String, dynamic>> getHealthResource(String id) async {
    final data = await _client.getJson('/api/health-resources/$id');
    return _asMap(data);
  }

  // Organization Admin
  Future<Map<String, dynamic>> getOrganizationBootstrapStatus() async {
    final data = await _client.getJson('/api/organization-bootstrap/status');
    return _asMap(data);
  }

  Future<List<dynamic>> getOrganizations() async {
    final data = await _client.getJson('/api/organizations');
    return _asList(data);
  }

  Future<Map<String, dynamic>> getOrganization(String id) async {
    final data = await _client.getJson('/api/organizations/$id');
    return _asMap(data);
  }

  Future<Map<String, dynamic>> createOrganization(
      Map<String, dynamic> payload) async {
    final data = await _client.postJson('/api/organizations', body: payload);
    return _asMap(data);
  }

  Future<Map<String, dynamic>> updateOrganization(
    String id,
    Map<String, dynamic> payload,
  ) async {
    final data =
        await _client.patchJson('/api/organizations/$id', body: payload);
    return _asMap(data);
  }

  Future<List<dynamic>> getOrganizationUsers(String orgId) async {
    final data = await _client.getJson('/api/organizations/$orgId/users');
    return _asList(data);
  }

  Future<Map<String, dynamic>> updateOrganizationUser({
    required String orgId,
    required String userId,
    required Map<String, dynamic> payload,
  }) async {
    final data = await _client.patchJson(
      '/api/organizations/$orgId/users/$userId',
      body: payload,
    );
    return _asMap(data);
  }

  Future<Map<String, dynamic>> createUser(Map<String, dynamic> payload) async {
    final data = await _client.postJson('/api/users', body: payload);
    return _asMap(data);
  }

  Future<Map<String, dynamic>> addOrganizationUser({
    required String orgId,
    required String userId,
    required String orgRole,
  }) async {
    final data = await _client.postJson(
      '/api/organizations/$orgId/users',
      body: {'userId': userId, 'orgRole': orgRole},
    );
    return _asMap(data);
  }

  Future<Map<String, dynamic>> deleteOrganizationUser({
    required String orgId,
    required String userId,
  }) async {
    final data =
        await _client.deleteJson('/api/organizations/$orgId/users/$userId');
    return _asMap(data);
  }

  Future<List<dynamic>> getInvitationCandidates() async {
    final data = await _client.getJson('/api/invitations/candidates');
    return _asList(data);
  }

  Future<List<dynamic>> getLicensePlans() async {
    final data = await _client.getJson('/api/license-plans');
    return _asList(data);
  }

  Future<Map<String, dynamic>> subscribeOrganization({
    required String orgId,
    required String priceId,
    required String planType,
    required int userLimit,
  }) async {
    final data = await _client.postJson(
      '/api/organizations/$orgId/subscribe',
      body: {
        'priceId': priceId,
        'planType': planType,
        'userLimit': userLimit,
      },
    );
    return _asMap(data);
  }

  Future<Map<String, dynamic>> getOrganizationLicense(String orgId) async {
    final data = await _client.getJson('/api/organizations/$orgId/license');
    return _asMap(data);
  }

  // Lab Integrations
  Future<List<dynamic>> getLabIntegrations() async {
    final data = await _client.getJson('/api/lab-integrations');
    return _asList(data);
  }

  Future<Map<String, dynamic>> createLabIntegration(
      Map<String, dynamic> payload) async {
    final data = await _client.postJson('/api/lab-integrations', body: payload);
    return _asMap(data);
  }

  Future<Map<String, dynamic>> updateLabIntegration(
    String id,
    Map<String, dynamic> payload,
  ) async {
    final data =
        await _client.patchJson('/api/lab-integrations/$id', body: payload);
    return _asMap(data);
  }

  Future<Map<String, dynamic>> regenerateLabIntegrationKey(String id) async {
    final data =
        await _client.postJson('/api/lab-integrations/$id/regenerate-key');
    return _asMap(data);
  }

  Future<Map<String, dynamic>> deleteLabIntegration(String id) async {
    final data = await _client.deleteJson('/api/lab-integrations/$id');
    return _asMap(data);
  }

  Future<Map<String, dynamic>> getLabIntegrationStats() async {
    final data = await _client.getJson('/api/lab-integrations/stats');
    return _asMap(data);
  }

  Future<Map<String, dynamic>> getLabIntegrationLogs({
    required String id,
    int? page,
    int? limit,
  }) async {
    final data = await _client.getJson(
      '/api/lab-integrations/$id/logs',
      query: _query({'page': page, 'limit': limit}),
    );
    return _asMap(data);
  }

  // Audit Logs
  Future<List<dynamic>> getAuditLogs({
    String? userId,
    String? entityType,
    String? entityId,
    String? action,
    String? startDate,
    String? endDate,
    int? limit,
    int? offset,
  }) async {
    final data = await _client.getJson(
      '/api/audit-logs',
      query: _query({
        'userId': userId,
        'entityType': entityType,
        'entityId': entityId,
        'action': action,
        'startDate': startDate,
        'endDate': endDate,
        'limit': limit,
        'offset': offset,
      }),
    );
    return _asList(data);
  }

  Future<Map<String, dynamic>> getAuditLogStats({
    String? startDate,
    String? endDate,
  }) async {
    final data = await _client.getJson(
      '/api/audit-logs/stats',
      query: _query({'startDate': startDate, 'endDate': endDate}),
    );
    return _asMap(data);
  }

  Future<dynamic> exportAuditLogs({String format = 'csv'}) async {
    if (format == 'json') {
      return _client.getJson(
        '/api/audit-logs/export',
        query: _query({'format': format}),
      );
    }
    return _client.getRaw(
      '/api/audit-logs/export',
      query: _query({'format': format}),
    );
  }

  // Inventory
  Future<List<dynamic>> getInventory({
    String? category,
    bool? lowStock,
    bool? expiringSoon,
    String? search,
  }) async {
    final data = await _client.getJson(
      '/api/inventory',
      query: _query({
        'category': category,
        'lowStock': lowStock,
        'expiringSoon': expiringSoon,
        'search': search,
      }),
    );
    return _asList(data);
  }

  Future<Map<String, dynamic>> getInventoryItem(String id) async {
    final data = await _client.getJson('/api/inventory/$id');
    return _asMap(data);
  }

  Future<Map<String, dynamic>> createInventory(
      Map<String, dynamic> payload) async {
    final data = await _client.postJson('/api/inventory', body: payload);
    return _asMap(data);
  }

  Future<Map<String, dynamic>> updateInventory(
    String id,
    Map<String, dynamic> payload,
  ) async {
    final data = await _client.patchJson('/api/inventory/$id', body: payload);
    return _asMap(data);
  }

  Future<Map<String, dynamic>> adjustInventory(
    String id,
    Map<String, dynamic> payload,
  ) async {
    final data =
        await _client.postJson('/api/inventory/$id/adjust', body: payload);
    return _asMap(data);
  }

  Future<List<dynamic>> getInventoryTransactions(String id) async {
    final data = await _client.getJson('/api/inventory/$id/transactions');
    return _asList(data);
  }

  Future<void> deleteInventory(String id) async {
    await _client.deleteJson('/api/inventory/$id');
  }

  // Chat
  Future<Map<String, dynamic>> getChatToken() async {
    final data = await _client.postJson('/api/chat/ws-token');
    return _asMap(data);
  }

  Future<List<dynamic>> getChatConversations() async {
    final data = await _client.getJson('/api/chat/conversations');
    return _asList(data);
  }

  Future<List<dynamic>> getAvailableChatUsers() async {
    final data = await _client.getJson('/api/chat/available-users');
    return _asList(data);
  }

  Future<Map<String, dynamic>> createChatConversation({
    required String participantId,
    String? title,
    String? type,
  }) async {
    final data = await _client.postJson(
      '/api/chat/conversations',
      body: {
        'participantId': participantId,
        'title': title,
        'type': type,
      },
    );
    return _asMap(data);
  }

  Future<List<dynamic>> getChatMessages({
    required String conversationId,
    int? limit,
    String? before,
  }) async {
    final data = await _client.getJson(
      '/api/chat/conversations/$conversationId/messages',
      query: _query({'limit': limit, 'before': before}),
    );
    return _asList(data);
  }

  Future<Map<String, dynamic>> sendChatMessage({
    required String conversationId,
    required String content,
    String? messageType,
  }) async {
    final data = await _client.postJson(
      '/api/chat/conversations/$conversationId/messages',
      body: {
        'content': content,
        'messageType': messageType,
      },
    );
    return _asMap(data);
  }

  // Partner Permissions
  Future<Map<String, dynamic>> getMyPermissions() async {
    final data = await _client.getJson('/api/my-permissions');
    return _asMap(data);
  }

  Future<List<dynamic>> getPartnerPermissions() async {
    final data = await _client.getJson('/api/partner-permissions');
    return _asList(data);
  }

  Future<Map<String, dynamic>> updatePartnerPermissions({
    required String partnerId,
    required Map<String, dynamic> payload,
  }) async {
    final data = await _client.putJson(
      '/api/partner-permissions/$partnerId',
      body: payload,
    );
    return _asMap(data);
  }

  // External Lab Endpoints
  Future<Map<String, dynamic>> submitLabResults({
    required Map<String, dynamic> payload,
    required String apiKey,
  }) async {
    final data = await _client.postJson(
      '/api/external/lab-results',
      body: _normalizeLabResultsPayload(payload),
      headers: _labAuthHeaders(apiKey),
    );
    return _asMap(data);
  }

  Future<Map<String, dynamic>> submitLabResultsBatch({
    required http.MultipartFile file,
    required String apiKey,
  }) async {
    final data = await _client.postMultipart(
      '/api/external/lab-results/batch',
      file: file,
      fields: const {},
      headers: _labAuthHeaders(apiKey),
    );
    return _asMap(data);
  }

  Future<List<dynamic>> getExternalLabImports({
    required String integrationId,
    int? page,
    int? limit,
  }) async {
    final data = await _client.getJson(
      '/api/lab-integrations/$integrationId/logs',
      query: _query({'page': page, 'limit': limit}),
    );
    final response = _asMap(data);
    return _asList(response['logs']);
  }

  Map<String, String> _query(Map<String, Object?> params) {
    final result = <String, String>{};
    params.forEach((key, value) {
      if (value == null) return;
      if (value is bool) {
        result[key] = value ? 'true' : 'false';
      } else {
        result[key] = value.toString();
      }
    });
    return result;
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }

  List<dynamic> _asList(dynamic value) {
    if (value is List) return value;
    return <dynamic>[];
  }

  List<dynamic> _asListWithKeys(dynamic value, List<String> keys) {
    if (value is List) return value;
    final map = _asMap(value);
    for (final key in keys) {
      final candidate = map[key];
      if (candidate is List) return candidate;
    }
    return <dynamic>[];
  }

  bool _isEndpointMissing(ApiException error) {
    return error.statusCode == 404 ||
        error.statusCode == 405 ||
        error.statusCode == 501;
  }

  bool _isPatientIdRequiredError(ApiException error) {
    final message = error.message.toLowerCase();
    return error.statusCode == 400 && message.contains('patient');
  }

  bool _isAccessRestricted(ApiException error) {
    return error.statusCode == 401 || error.statusCode == 403;
  }

  String? _resolvePatientIdentifier(Map<String, dynamic> user) {
    const candidateKeys = [
      'patientId',
      'patient_id',
      'id',
      'userId',
      'user_id',
    ];
    for (final key in candidateKeys) {
      final value = user[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  Map<String, String> _labAuthHeaders(String apiKey) {
    return {'Authorization': 'Bearer $apiKey'};
  }

  Map<String, dynamic> _normalizeLabResultsPayload(
      Map<String, dynamic> payload) {
    final normalized = Map<String, dynamic>.from(payload);

    final patientIdentifier = normalized['patientIdentifier'] ??
        normalized['patient_id'] ??
        normalized['patientId'];
    if (patientIdentifier != null &&
        patientIdentifier.toString().trim().isNotEmpty) {
      normalized['patientIdentifier'] = patientIdentifier.toString().trim();
    }

    final identifierType = normalized['identifierType'];
    if (identifierType == null || identifierType.toString().trim().isEmpty) {
      normalized['identifierType'] = 'patient_id';
    }

    normalized.remove('patientId');
    normalized.remove('patient_id');

    return normalized;
  }
}
