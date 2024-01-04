/**
 * @description A REST API test class for the DeleteTranscript class
 */
@IsTest
private class DeleteTranscript_REST_Test {
    @TestSetup
    private static void setup() {
        createUser('noperm', 'noPermissionsTestUser@invalid.invalid', 'Standard User');

        User testUser = createUser('standt', 'testUser@invalid.invalid', 'API_Only');
        assignPermissionSet(testUser, 'Delete_Transcripts_REST');

        User adminUser = createUser('admint', 'testAdmin@invalid.invalid', 'System Administrator');
        System.runAs(adminUser) {
            createConversationData();
        }
    }

    @IsTest
    static void testDeleteTranscript() {
        User testUser = [SELECT Id FROM User WHERE Username = 'testUser@invalid.invalid'];
        System.runAs(testUser) {
            List<Conversation> conversations = [SELECT Id, ConversationIdentifier FROM Conversation];

            RestRequest req = new RestRequest();
            RestResponse res = new RestResponse();

            req.requestURI = '/services/apexrest/DeleteTranscript';
            req.httpMethod = 'POST';

            req.addHeader('Content-Type', 'application/json');
            req.requestBody = Blob.valueOf(JSON.serialize(new Map<String, String>{
                    'vendorCallKey' => conversations[0].ConversationIdentifier
            }));

            Test.startTest();
            RestContext.request = req;
            RestContext.response = res;

            DeleteTranscript_REST.deleteTranscript();
            Test.stopTest();

            Assert.areEqual(204, res.statusCode, 'Expected status code: ' + 204 + ' but got: ' + res.statusCode);
        }
    }

    @IsTest
    static void testInvalidRequestException() {
        User testUser = [SELECT Id FROM User WHERE Username = 'testUser@invalid.invalid'];
        System.runAs(testUser) {
            RestRequest req = new RestRequest();
            RestResponse res = new RestResponse();
            req.requestURI = '/services/apexrest/DeleteTranscript';
            req.httpMethod = 'POST';
            req.requestBody = Blob.valueOf(JSON.serialize(new Map<String, String>{
            }));

            Test.startTest();
            RestContext.request = req;
            RestContext.response = res;

            DeleteTranscript_REST.deleteTranscript();
            Test.stopTest();

            Assert.areEqual(400, res.statusCode, 'Expected status code: ' + 400 + ' but got: ' + res.statusCode);
        }
    }

    @IsTest
    static void testInvalidVendorCallKeyException() {
        User testUser = [SELECT Id FROM User WHERE Username = 'testUser@invalid.invalid'];
        System.runAs(testUser) {
            RestRequest req = new RestRequest();
            RestResponse res = new RestResponse();
            req.requestURI = '/services/apexrest/DeleteTranscript';
            req.httpMethod = 'POST';
            req.requestBody = Blob.valueOf(JSON.serialize(new Map<String, String>{
                    'vendorCallKey' => 'Invalid Vendor Call Key'
            }));

            Test.startTest();
            RestContext.request = req;
            RestContext.response = res;

            DeleteTranscript_REST.deleteTranscript();
            Test.stopTest();

            Assert.areEqual(404, res.statusCode, 'Expected status code: ' + 404 + ' but got: ' + res.statusCode);
        }
    }

    @IsTest
    static void testInvalidPermissionException() {
        User testUser = [SELECT Id FROM User WHERE Username = 'noPermissionsTestUser@invalid.invalid'];
        System.runAs(testUser) {
            RestRequest req = new RestRequest();
            RestResponse res = new RestResponse();
            req.requestURI = '/services/apexrest/DeleteTranscript';
            req.httpMethod = 'POST';
            req.requestBody = Blob.valueOf(JSON.serialize(new Map<String, String>{
                    'vendorCallKey' => 'Invalid Vendor Call Key'
            }));

            Test.startTest();
            RestContext.request = req;
            RestContext.response = res;

            DeleteTranscript_REST.deleteTranscript();
            Test.stopTest();

            // 404 is returned because the user does not have access to the Conversation object
            Assert.areEqual(404, res.statusCode, 'Expected status code: ' + 404 + ' but got: ' + res.statusCode);
        }
    }

    static User createUser(String alias, String email, String profileName) {
        Profile p = [SELECT Id FROM Profile WHERE Name = :profileName];
        User user = new User(
                Alias = alias,
                Username = email,
                Email = email,
                EmailEncodingKey = 'UTF-8',
                LastName = 'Testing',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = p.Id,
                TimeZoneSidKey = 'America/Los_Angeles'
        );
        insert user;
        return user;
    }

    static void assignPermissionSet(User user, String psName) {
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = :psName];
        PermissionSetAssignment psa = new PermissionSetAssignment(
                AssigneeId = user.Id,
                PermissionSetId = ps.Id
        );
        insert psa;
    }

    static void createConversationData() {
        List<SObject> conversations = Test.loadData(Conversation.SObjectType, 'ConversationTestData');
        List<ConversationEntry> conversationEntries = new List<ConversationEntry>();
        for (Integer i = 0; i < conversations.size(); i++) {
            Conversation conversation = (Conversation) conversations.get(i);

            conversationEntries.add(new ConversationEntry(
                    ConversationId = conversation.Id,
                    EntryType = 'Text',
                    ActorType = 'Agent',
                    Message = 'Test Message',
                    Seq = i,
                    EntryTime = Datetime.now()
            ));
            conversationEntries.add(new ConversationEntry(
                    ConversationId = conversation.Id,
                    EntryType = 'Text',
                    ActorType = 'System',
                    Message = 'Test Message',
                    Seq = i + conversations.size(),
                    EntryTime = Datetime.now()
            ));
        }
        insert conversationEntries;
    }
}