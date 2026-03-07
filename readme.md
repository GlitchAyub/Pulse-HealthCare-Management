# HealthReach API Architecture (Flutter Map)

## Purpose
This README maps frontend pages to backend API endpoints, with request and response shapes for building a Flutter client.

## Architecture Summary
- Frontend: React + Wouter routing (client/src/App.tsx).
- Layout: Header + Sidebar (and BottomNav on mobile) wrap authenticated pages.
- Auth: useAuth calls GET /api/auth/user. Sessions use cookies (credentials: include).
- Data: React Query + apiRequest (client/src/lib/queryClient.ts).
- Backend: Express routes in server/routes/* and auth in server/replitAuth.ts.
- Models: shared/schema.ts is the canonical field list.

## API Conventions
- Base path: /api
- Internal endpoints require a session cookie; roles are enforced in middleware.
- External lab endpoints use API key auth (Bearer token).
- Responses are JSON unless noted (redirects, CSV export).
- Dates are ISO strings.
- Field naming is mixed: SQL-based routes return snake_case, storage-based routes return camelCase. Handle both in Flutter.

## Core Response Models
### User
| Field | Type | Notes |
| --- | --- | --- |
| id | string | UUID |
| username | string | |
| email | string or null | |
| firstName | string or null | |
| lastName | string or null | |
| role | string | patient, medical_professional, institutional_partner, admin |
| facilityId | string or null | |
| organizationId | string or null | |
| createdAt | string | ISO |
| updatedAt | string | ISO |

### Organization
| Field | Type | Notes |
| id | string | |
| name | string | |
| type | string | private_hospital, government_hospital, clinic, health_center |
| address | string or null | |
| phone | string or null | |
| email | string or null | |
| website | string or null | |
| logo | string or null | |
| stripeCustomerId | string or null | |
| isActive | boolean | |
| createdAt | string | ISO |
| updatedAt | string | ISO |

### OrganizationUser (join)
| Field | Type | Notes |
| id | string | |
| organization_id | string | |
| user_id | string | |
| org_role | string | org_admin, member, patient, institutional_partner |
| status | string | active, suspended, pending |
| invited_by | string or null | |
| invited_at | string or null | ISO |
| joined_at | string or null | ISO |
| username | string | from users |
| email | string or null | from users |
| first_name | string or null | from users |
| last_name | string or null | from users |
| role | string | from users |

### License
| Field | Type | Notes |
| id | string | |
| organization_id | string | |
| plan_type | string | basic, professional, enterprise |
| stripe_subscription_id | string or null | |
| stripe_price_id | string or null | |
| status | string | active, expired, cancelled, pending |
| user_limit | number | |
| start_date | string | ISO |
| end_date | string | ISO |
| auto_renew | boolean | |
| created_at | string | ISO |
| updated_at | string | ISO |

### LicensePlan
| Field | Type | Notes |
| product_id | string | Stripe product id |
| product_name | string | |
| product_description | string or null | |
| product_metadata | object | |
| price_id | string | Stripe price id |
| unit_amount | number | |
| currency | string | |
| recurring | object | |

### Invitation
| Field | Type | Notes |
| id | string | |
| email | string | |
| first_name | string or null | |
| last_name | string or null | |
| role | string | medical_professional, admin, patient, institutional_partner |
| token | string | |
| status | string | pending, accepted, expired, cancelled |
| expires_at | string | ISO |
| created_at | string | ISO |
| accepted_at | string or null | ISO |
| invited_by_name | string | admin username |
| organization_name | string | from org |

### AppointmentRequest
| Field | Type | Notes |
| id | string | |
| patient_id | string | |
| patient_user_id | string | |
| organization_id | string or null | |
| request_type | string | consultation, checkup, followup, specialist |
| visit_mode | string | in_person, virtual |
| preferred_date | string or null | ISO |
| preferred_time_slot | string or null | morning, afternoon, evening |
| reason | string | |
| urgency | string | normal, urgent |
| status | string | pending, approved, rejected, scheduled, cancelled |
| assigned_doctor_id | string or null | |
| scheduled_consultation_id | string or null | |
| admin_notes | string or null | |
| rejection_reason | string or null | |
| created_at | string | ISO |
| updated_at | string | ISO |
| responded_at | string or null | ISO |
| responded_by | string or null | |
| patient_first_name | string or null | join field |
| patient_last_name | string or null | join field |

### Patient
| Field | Type | Notes |
| id | string | |
| patientId | string | HC001234 format |
| fullName | string | |
| dateOfBirth | string or null | ISO |
| age | number or null | |
| gender | string or null | |
| phone | string or null | |
| address | string or null | |
| emergencyContact | string or null | |
| medicalHistory | object or null | |
| familyHistory | object or null | |
| allergies | string or null | |
| bloodType | string or null | A+, A-, etc |
| pharmacyInfo | object or null | |
| lastSeenDoctor | string or null | |
| lastSeenDate | string or null | ISO |
| createdAt | string | ISO |
| updatedAt | string | ISO |
| createdBy | string or null | user id |

### Visit
| Field | Type | Notes |
| id | string | |
| patientId | string | |
| visitType | string | checkup, followup, emergency, vaccination |
| chiefComplaint | string or null | |
| symptoms | string or null | |
| vitals | object or null | |
| diagnosis | string or null | |
| treatment | string or null | |
| medications | object or null | |
| followUpRequired | string | no, 1week, 2weeks, 1month, 3months |
| followUpDate | string or null | ISO |
| urgencyLevel | string | low, medium, high, critical |
| visitDate | string | ISO |
| createdAt | string | ISO |
| healthWorkerId | string or null | |

### Consultation
| Field | Type | Notes |
| id | string | |
| patientId | string or null | |
| doctorId | string or null | |
| healthWorkerId | string or null | |
| scheduledTime | string | ISO |
| status | string | scheduled, active, completed, cancelled |
| consultationType | string | general, specialist, emergency |
| notes | string or null | |
| recommendations | string or null | |
| callStartTime | string or null | ISO |
| callEndTime | string or null | ISO |
| recordingUrl | string or null | |
| recordingSize | number or null | |
| recordingDuration | number or null | |
| isRecorded | boolean | |
| recordingConsent | boolean | |
| sharedFiles | object or null | |
| callQuality | string or null | excellent, good, fair, poor |
| technicalIssues | string or null | |
| createdAt | string | ISO |

### ConsultationFile
| Field | Type | Notes |
| id | string | |
| consultationId | string | |
| fileName | string | |
| fileUrl | string | |
| fileType | string | image, document, video, audio |
| fileSize | number | bytes |
| uploadedBy | string or null | |
| uploadedAt | string | ISO |
| isSharedWithPatient | boolean | |
| description | string or null | |

### Medication
| Field | Type | Notes |
| id | string | |
| patientId | string | |
| medicationName | string | |
| dosage | string | |
| frequency | string | daily, twice_daily, weekly, etc |
| startDate | string | ISO |
| endDate | string or null | ISO |
| instructions | string or null | |
| prescribedBy | string or null | |
| adherenceNotes | string or null | |
| isActive | boolean | |
| createdAt | string | ISO |

### LabTest
| Field | Type | Notes |
| id | string | |
| patientId | string | |
| testName | string | |
| testType | string | blood, urine, etc |
| orderedBy | string or null | |
| orderedDate | string | ISO |
| collectionDate | string or null | ISO |
| resultDate | string or null | ISO |
| status | string | ordered, collected, processing, completed, cancelled |
| results | object | |
| interpretation | string or null | Normal, Abnormal, Critical |
| notes | string or null | |
| labName | string or null | |
| referenceRanges | object or null | |
| attachmentUrl | string or null | |
| createdAt | string | ISO |

### ImagingReport
| Field | Type | Notes |
| id | string | |
| patientId | string | |
| imagingType | string | xray, ct, mri, ultrasound, etc |
| bodyPart | string | |
| orderedBy | string or null | |
| orderedDate | string | ISO |
| performedDate | string or null | ISO |
| radiologist | string or null | |
| findings | string or null | |
| impression | string or null | |
| recommendations | string or null | |
| status | string | ordered, scheduled, completed, cancelled |
| urgency | string | routine, urgent, stat |
| imageUrls | object or null | |
| reportUrl | string or null | |
| createdAt | string | ISO |

### HealthResource
| Field | Type | Notes |
| id | string | |
| title | string | |
| description | string or null | |
| category | string | |
| content | string or null | |
| fileUrl | string or null | |
| language | string | |
| downloadCount | number | |
| tags | array of string or null | |
| isOfflineAvailable | boolean | |
| createdAt | string | ISO |
| updatedAt | string | ISO |

### MedicationInventory
| Field | Type | Notes |
| id | string | |
| organization_id | string or null | |
| medication_name | string | |
| generic_name | string or null | |
| category | string | |
| formulation | string | |
| strength | string | |
| manufacturer | string or null | |
| batch_number | string or null | |
| expiration_date | string or null | ISO |
| quantity_in_stock | number | |
| unit_of_measure | string | |
| reorder_level | number | |
| reorder_quantity | number or null | |
| unit_cost | number or null | cents |
| location | string or null | |
| requires_prescription | boolean | |
| is_controlled_substance | boolean | |
| storage_conditions | string or null | |
| notes | string or null | |
| is_active | boolean | |
| created_at | string | ISO |
| updated_at | string | ISO |
| created_by | string or null | |

### InventoryTransaction
| Field | Type | Notes |
| id | string | |
| inventory_item_id | string | |
| transaction_type | string | received, dispensed, adjusted, expired, returned, transferred |
| quantity | number | positive or negative |
| previous_quantity | number | |
| new_quantity | number | |
| reason | string or null | |
| reference_number | string or null | |
| patient_id | string or null | |
| batch_number | string or null | |
| expiration_date | string or null | ISO |
| unit_cost | number or null | |
| performed_by | string or null | |
| performed_at | string | ISO |
| notes | string or null | |
| first_name | string or null | join field |
| last_name | string or null | join field |
| username | string or null | join field |

### Notification
| Field | Type | Notes |
| id | string | |
| user_id | string | |
| organization_id | string or null | |
| type | string | lab_result, appointment, message, system |
| title | string | |
| message | string | |
| related_entity_type | string or null | |
| related_entity_id | string or null | |
| is_read | boolean | |
| created_at | string | ISO |

### ChatConversation
| Field | Type | Notes |
| id | string | |
| organization_id | string or null | |
| title | string or null | |
| type | string | direct, group |
| created_by | string or null | |
| created_at | string | ISO |
| updated_at | string | ISO |
| last_message_at | string or null | ISO |
| participants | array | { id, username, firstName, lastName } |
| last_message | string or null | |
| unread_count | string | SQL count as string |

### ChatMessage
| Field | Type | Notes |
| id | string | |
| conversation_id | string | |
| sender_id | string | |
| content | string | |
| message_type | string | text, file, image, system |
| file_url | string or null | |
| file_name | string or null | |
| is_edited | boolean | |
| is_deleted | boolean | |
| created_at | string | ISO |
| updated_at | string | ISO |
| username | string | join field |
| first_name | string or null | join field |
| last_name | string or null | join field |

### LabIntegration
| Field | Type | Notes |
| id | string | |
| organization_id | string | |
| lab_name | string | |
| lab_code | string | |
| api_key_prefix | string | |
| contact_email | string or null | |
| contact_phone | string or null | |
| is_active | boolean | |
| last_sync_at | string or null | ISO |
| created_at | string | ISO |
| updated_at | string | ISO |
| apiKey | string | returned only on create/regenerate |
| webhookSecret | string | returned only on create |

### LabImportLog
| Field | Type | Notes |
| id | string | |
| integration_id | string | |
| organization_id | string | |
| external_order_id | string or null | |
| patient_id | string or null | |
| lab_test_id | string or null | |
| status | string | success, failed, pending_review, duplicate |
| error_message | string or null | |
| raw_payload | object | |
| patient_match_method | string or null | patient_id, mrn, name_dob |
| imported_at | string | ISO |
| patient_name | string or null | join field |
| patient_identifier | string or null | join field |

### PartnerPermission
| Field | Type | Notes |
| partner_id | string | |
| username | string | |
| first_name | string or null | |
| last_name | string or null | |
| email | string or null | |
| can_view_patient_stats | boolean | |
| can_view_visit_stats | boolean | |
| can_view_consultation_stats | boolean | |
| can_view_demographics | boolean | |
| can_view_condition_stats | boolean | |
| can_view_education_stats | boolean | |
| can_view_medication_stats | boolean | |
| can_export_reports | boolean | |

### AuditLog
| Field | Type | Notes |
| id | string | |
| user_id | string or null | |
| organization_id | string or null | |
| action | string | create, read, update, delete, export |
| entity_type | string | patient, visit, medication, etc |
| entity_id | string or null | |
| previous_value | object or null | |
| new_value | object or null | |
| metadata | object or null | |
| ip_address | string or null | |
| user_agent | string or null | |
| session_id | string or null | |
| status | string | success, failed, denied |
| error_message | string or null | |
| duration | number or null | ms |
| created_at | string | ISO |
| userName | string | resolved name |

### Stats
- DashboardStats: { activePatients, todayVisits, upcomingConsultations, criticalCases }
- InventoryStats: { totalItems, lowStock, expiringSoon, expired, outOfStock, byCategory[] }
- LabIntegrationStats: { integrations[], totalTests, recentTests[] }
- UnreadCount: { count }

## Page to API Map
### Public Pages
#### Login (shown when unauthenticated)
File: client/src/pages/login.tsx
| Method | Endpoint | Request | Response | Auth/Role | Notes |
| --- | --- | --- | --- | --- | --- |
| POST | /api/login | { email, password } | { id, email, firstName, lastName, role } | Public | Local auth. Replit uses GET /api/login redirect. |
| POST | /api/register | { email, password, firstName, lastName, role } | { id, email, firstName, lastName, role } | Public | Role is validated server-side. |
| GET | /api/auth/user | none | User | Session | Used by useAuth after login. |

#### Accept Invitation (/accept-invitation/:token)
File: client/src/pages/accept-invitation.tsx
| Method | Endpoint | Request | Response | Auth/Role | Notes |
| --- | --- | --- | --- | --- | --- |
| GET | /api/invitations/token/:token | none | Invitation (includes organization_name) | Public | Validates token and status. |
| POST | /api/invitations/token/:token/accept | none | { message, role, organizationId } | Auth required | Updates user role and org membership. |
| GET | /api/login | none | redirect | Public | Replit login flow. |

#### Lab Submit (/lab-submit)
File: client/src/pages/lab-submit.tsx
| Method | Endpoint | Request | Response | Auth/Role | Notes |
| --- | --- | --- | --- | --- | --- |
| POST | /api/external/lab-results | JSON body, Authorization: Bearer API_KEY | { message, labTestId } or error | Public (API key) | Required: patientIdentifier, identifierType, testName, testType, results. |
| POST | /api/external/lab-results/batch | multipart/form-data with file, Authorization: Bearer API_KEY | { message, success, failed, total, errors[] } | Public (API key) | CSV columns: patient_id, test_name, test_type, results, etc. |

#### Lab Portal (/lab-portal)
File: client/src/pages/lab-portal.tsx
| Method | Endpoint | Request | Response | Auth/Role | Notes |
| --- | --- | --- | --- | --- | --- |
| POST | /api/external/lab-results | JSON body, X-Lab-API-Key header | { message, labTestId } | Public (API key) | Client uses X-Lab-API-Key but server expects Authorization: Bearer. |
| GET | /api/external/lab-imports | none | LabImportLog[] | Public (API key) | Not implemented on server. |

### Authenticated Layout (all logged-in pages)
Components: client/src/components/layout/header.tsx, client/src/components/layout/sidebar.tsx
| Method | Endpoint | Request | Response | Auth/Role | Notes |
| --- | --- | --- | --- | --- | --- |
| GET | /api/notifications | query: unreadOnly, limit | Notification[] | Session | Supports unreadOnly=true. |
| GET | /api/notifications/unread-count | none | { count } | Session | |
| PATCH | /api/notifications/:id/read | none | { message } | Session | Header uses PATCH. NotificationTray uses POST (mismatch). |
| POST | /api/notifications/mark-all-read | none | { message } | Session | NotificationTray uses /api/notifications/read-all (mismatch). |
| GET | /api/logout | none | redirect | Session | Ends session. |

### Dashboard (/) role-based
File: client/src/pages/dashboard.tsx

#### Admin Dashboard
File: client/src/pages/dashboards/admin-dashboard.tsx
Components: KPIPanel, CriticalActionQueue, StaffManagement, LicensePanel
| Method | Endpoint | Request | Response | Auth/Role | Notes |
| --- | --- | --- | --- | --- | --- |
| GET | /api/my-organization | none | Organization + org_role, plan_type, license_status, user_limit, end_date | Session | Used to derive orgId. |
| GET | /api/dashboard/stats | none | DashboardStats | Session | |
| GET | /api/appointment-requests?status=pending | none | AppointmentRequest[] | Staff | Admin or medical_professional. |
| PATCH | /api/appointment-requests/:id | { status, adminNotes?, rejectionReason?, assignedDoctorId? } | AppointmentRequest | Staff | Approve or reject. |
| GET | /api/inventory-stats | none | InventoryStats | Staff | Used in CriticalActionQueue. |
| GET | /api/organizations/:orgId/users | none | OrganizationUser[] | Session | Used by StaffManagement and LicensePanel. |
| PATCH | /api/organizations/:orgId/users/:userId | { orgRole?, status? } | OrganizationUser | Session | Update org role or status. |
| GET | /api/organizations/:orgId/license | none | License or null | Session | LicensePanel. |

#### Professional Dashboard
File: client/src/pages/dashboards/professional-dashboard.tsx
Components: StatsCards, PatientRegistrationForm, PatientList, ConsultationPanel, SOAPNoteForm
| Method | Endpoint | Request | Response | Auth/Role | Notes |
| --- | --- | --- | --- | --- | --- |
| GET | /api/dashboard/stats | none | DashboardStats | Session | StatsCards. |
| GET | /api/appointment-requests?status=pending | none | AppointmentRequest[] | Staff | |
| PATCH | /api/appointment-requests/:id | { status, rejectionReason? } | AppointmentRequest | Staff | |
| GET | /api/patients | query: search, limit, offset, filterCritical | Patient[] | Staff | PatientList. |
| POST | /api/patients | InsertPatient | Patient | Staff | PatientRegistrationForm. |
| GET | /api/visits | query: patientId | Visit[] | Staff | Patient detail views. |
| PATCH | /api/visits/:id | Partial Visit | Visit | Staff | SOAPNoteForm uses { soapNotes, icdCodes }. |
| GET | /api/lab-tests | query: patientId | LabTest[] | Staff | Patient detail views. |
| GET | /api/imaging-reports | query: patientId | ImagingReport[] | Staff | Patient detail views. |
| GET | /api/medications | query: patientId | Medication[] | Staff | Patient detail views. |
| GET | /api/consultations | query: upcoming=true | Consultation[] | Staff | ConsultationPanel. |
| POST | /api/consultations | InsertConsultation | Consultation | Staff | Schedule consult. |
| PATCH | /api/consultations/:id | Partial Consultation | Consultation | Staff | Join and update. |

#### Patient Dashboard
File: client/src/pages/dashboards/patient-dashboard.tsx
Components: VisitTimeline, MedicationDashboard, JoinSession
| Method | Endpoint | Request | Response | Auth/Role | Notes |
| --- | --- | --- | --- | --- | --- |
| GET | /api/appointment-requests | none | AppointmentRequest[] | Patient | Own requests only. |
| POST | /api/appointment-requests | { requestType, visitMode, preferredDate, preferredTimeSlot, reason, urgency } | AppointmentRequest | Patient | Submit request. |
| DELETE | /api/appointment-requests/:id | none | { message } | Patient | Cancel pending request. |
| GET | /api/visits | none | Visit[] | Staff only | Client calls without patientId; server is staff-only. |
| GET | /api/medications | none | Medication[] | Staff only | Server requires patientId. |
| GET | /api/consultations | none | Consultation[] | Staff only | Server is staff-only. |

#### Partner Dashboard
File: client/src/pages/dashboards/partner-dashboard.tsx
Components: AnalyticsOverview
| Method | Endpoint | Request | Response | Auth/Role | Notes |
| --- | --- | --- | --- | --- | --- |
| GET | /api/my-permissions | none | PartnerPermission (camelCase) | Session | Partners only. |
| GET | /api/dashboard/stats | none | DashboardStats | Session | Aggregated stats. |

### Patients Page (/patients)
File: client/src/pages/patients.tsx
Components: PatientRegistrationForm, PatientList
| Method | Endpoint | Request | Response | Auth/Role | Notes |
| --- | --- | --- | --- | --- | --- |
| GET | /api/patients | query: search, limit, offset, filterCritical | Patient[] | Staff | |
| POST | /api/patients | InsertPatient | Patient | Staff | |
| GET | /api/visits | query: patientId | Visit[] | Staff | Patient detail dialog. |
| GET | /api/lab-tests | query: patientId | LabTest[] | Staff | Patient detail dialog. |
| GET | /api/imaging-reports | query: patientId | ImagingReport[] | Staff | Patient detail dialog. |
| GET | /api/medications | query: patientId | Medication[] | Staff | Patient detail dialog. |

### Visits Page (/visits)
File: client/src/pages/visits.tsx
Components: VisitDocumentationForm
| Method | Endpoint | Request | Response | Auth/Role | Notes |
| --- | --- | --- | --- | --- | --- |
| GET | /api/visits | query: patientId, limit | Visit[] | Staff | useVisits hook. |
| POST | /api/visits | InsertVisit | Visit | Staff | VisitDocumentationForm. |
| PATCH | /api/visits/:id | Partial Visit | Visit | Staff | SOAP notes and updates. |

### Telemedicine Page (/telemedicine)
File: client/src/pages/telemedicine.tsx
Components: ConsultationPanel, VideoConsultation, FileSharingPanel
| Method | Endpoint | Request | Response | Auth/Role | Notes |
| --- | --- | --- | --- | --- | --- |
| GET | /api/consultations | query: upcoming=true, patientId | Consultation[] | Staff | useConsultations hook. |
| POST | /api/consultations | InsertConsultation | Consultation | Staff | Schedule consult. |
| PATCH | /api/consultations/:id | Partial Consultation | Consultation | Staff | Join and update. |
| GET | /api/patients | query: search, limit | Patient[] | Staff | Patient picker for scheduling. |
| GET | /api/consultations/:id/files | none | ConsultationFile[] | Staff | FileSharingPanel. |
| POST | /api/consultations/:id/files | FormData fields | ConsultationFile | Staff | fileName, fileType, fileSize, description, isSharedWithPatient. |
| DELETE | /api/consultations/:id/files/:fileId | none | { message } | Staff | Delete file. |

### Education Page (/education)
File: client/src/pages/education.tsx
Components: ResourceLibrary
| Method | Endpoint | Request | Response | Auth/Role | Notes |
| --- | --- | --- | --- | --- | --- |
| GET | /api/health-resources | query: search, category | HealthResource[] | Public | No auth required. |
| GET | /api/health-resources/:id | none | HealthResource | Public | Increments download count. |

### Medication Page (/medication)
File: client/src/pages/medication.tsx
Components: MedicationTracker
| Method | Endpoint | Request | Response | Auth/Role | Notes |
| --- | --- | --- | --- | --- | --- |
| GET | /api/medications/my | none | Medication[] | Patient | Not implemented on server. |
| GET | /api/patients | query: limit | Patient[] | Staff | MedicationTracker patient select. |
| GET | /api/medications | query: patientId | Medication[] | Staff | MedicationTracker list. |

### Org Admin Page (/org-admin)
File: client/src/pages/org-admin.tsx
| Method | Endpoint | Request | Response | Auth/Role | Notes |
| --- | --- | --- | --- | --- | --- |
| GET | /api/my-organization | none | Organization + org_role, plan_type, license_status, user_limit, end_date | Session | |
| GET | /api/organizations/:orgId/users | none | OrganizationUser[] | Session | |
| POST | /api/users | { username, email, firstName, lastName, role, organizationId } | User | Session | Create user before adding to org. |
| POST | /api/organizations/:orgId/users | { userId, orgRole } | OrganizationUser | Session | Enforces license user_limit for staff roles. |
| PATCH | /api/organizations/:orgId/users/:userId | { orgRole?, status? } | OrganizationUser | Session | |
| DELETE | /api/organizations/:orgId/users/:userId | none | { message } | Session | |
| GET | /api/license-plans | none | LicensePlan[] | Public | Stripe product/price list. |
| POST | /api/organizations/:orgId/subscribe | { priceId, planType, userLimit } | { url } | Session | Redirect to Stripe checkout. |
| GET | /api/lab-integrations | none | LabIntegration[] | Admin | |
| POST | /api/lab-integrations | { labName, labCode, contactEmail?, contactPhone? } | LabIntegration + apiKey + webhookSecret | Admin | apiKey only returned once. |
| PATCH | /api/lab-integrations/:id | { labName?, contactEmail?, contactPhone?, isActive? } | LabIntegration | Admin | |
| POST | /api/lab-integrations/:id/regenerate-key | none | LabIntegration + apiKey | Admin | New apiKey returned. |
| DELETE | /api/lab-integrations/:id | none | { message } | Admin | |
| GET | /api/lab-integrations/stats | none | LabIntegrationStats | Admin | includes recentTests. |
| GET | /api/lab-integrations/:id/logs | query: page, limit | { logs: LabImportLog[], pagination } | Admin | |
| GET | /api/invitations | none | Invitation[] | Admin | |
| POST | /api/invitations | { email, firstName?, lastName?, role } | Invitation + invitationLink | Admin | |
| DELETE | /api/invitations/:id | none | { message } | Admin | |
| POST | /api/invitations/:id/resend | none | Invitation + invitationLink | Admin | |
| GET | /api/audit-logs | query: userId, entityType, entityId, action, startDate, endDate, limit, offset | AuditLog[] | Admin | |
| GET | /api/audit-logs/export?format=csv | none | CSV download | Admin | format=json also supported. |

### Inventory Page (/inventory)
File: client/src/pages/inventory.tsx
| Method | Endpoint | Request | Response | Auth/Role | Notes |
| --- | --- | --- | --- | --- | --- |
| GET | /api/inventory | query: category, lowStock, expiringSoon, search | MedicationInventory[] | Staff | |
| POST | /api/inventory | Inventory payload | MedicationInventory | Staff | Required: medicationName, category, formulation, strength. |
| POST | /api/inventory/:id/adjust | { transactionType, quantity, reason?, notes? } | { transaction, newQuantity } | Staff | Updates stock and creates transaction. |
| GET | /api/inventory/:id/transactions | none | InventoryTransaction[] | Staff | Includes performer name fields. |
| GET | /api/inventory-stats | none | InventoryStats | Staff | |

### Chat Page (/chat)
File: client/src/pages/chat.tsx
| Method | Endpoint | Request | Response | Auth/Role | Notes |
| --- | --- | --- | --- | --- | --- |
| POST | /api/chat/ws-token | none | { token, expiresAt } | Staff | Used to auth WebSocket. |
| GET | /api/chat/conversations | none | ChatConversation[] | Staff | Includes participants, last_message, unread_count. |
| GET | /api/chat/available-users | none | { id, username, first_name, last_name, role }[] | Staff | Same org only. |
| POST | /api/chat/conversations | { participantId, title?, type? } | ChatConversation or { id, isExisting } | Staff | Direct chat creation. |
| GET | /api/chat/conversations/:id/messages | query: limit, before | ChatMessage[] | Staff | Updates last_read_at. |
| POST | /api/chat/conversations/:id/messages | { content, messageType? } | ChatMessage | Staff | Broadcasts via WebSocket. |
| WS | /ws | { type: "auth", token } | { type: "auth_success" } | Staff | WebSocket for typing and new messages. |

### Partner Permissions Page (/partner-permissions)
File: client/src/pages/partner-permissions.tsx
| Method | Endpoint | Request | Response | Auth/Role | Notes |
| --- | --- | --- | --- | --- | --- |
| GET | /api/partner-permissions | none | PartnerPermission[] | Admin | |
| PUT | /api/partner-permissions/:partnerId | { canViewPatientStats?, ... } | { message } | Admin | Booleans only. |

## Known Mismatches and Gaps
- /api/medications/my is called in client/src/pages/medication.tsx but no server route exists.
- /api/consultations/:id GET is used in useConsultation but no server route exists.
- /api/consultations is staff-only; patient dashboards and telemedicine patient view call it.
- /api/visits is staff-only; patient dashboards and visits page use it for patients.
- /api/medications requires patientId; patient dashboard calls it without patientId.
- /api/notifications/read-all does not exist; server provides /api/notifications/mark-all-read.
- /api/notifications/:id/read is PATCH on server; NotificationTray uses POST.
- Lab Portal uses X-Lab-API-Key; server expects Authorization: Bearer for /api/external/lab-results.
- /api/external/lab-imports is referenced in Lab Portal but not implemented.
- Admin Dashboard renders StaffManagement and LicensePanel without organizationId props.
- Professional Dashboard renders SOAPNoteForm without required visitId.

## Flutter Implementation Notes
- Use cookie-based auth for internal endpoints; include credentials (cookies) in HTTP client.
- Expect mixed casing in responses; consider a normalization layer.
- Roles matter: many endpoints are restricted to admin or medical_professional.
- External lab endpoints are public but require API key via Bearer token.
