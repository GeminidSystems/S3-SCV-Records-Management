/**
 * @description A REST API to delete a transcript record given a vendorCallKey
 */
@RestResource(UrlMapping='/DeleteTranscript/*')
global with sharing class DeleteTranscript_REST {

    /**
     * @description Represents an exception for an invalid request
     */
    public class InvalidRequestException extends Exception {}

    /**
     * @description Represents an exception for an invalid vendor call key
     */
    public class InvalidVendorCallKeyException extends Exception {}

    /**
    * @description Represents an exception for an error with the delete operation
    */
    public class DeleteException extends Exception {}

    /**
     * @description Handles the HTTP POST request to delete a transcription
     * @return Returns an empty string if deletion was successful; otherwise, returns an error message
     */
    @HttpPost
    global static String deleteTranscript() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        TranscriptionDeleteRequest tdr;

        try {
            tdr = new TranscriptionDeleteRequest(req.requestBody.toString());
            deleteTranscript(tdr);
            res.statusCode = 204;
            return '';
        } catch (InvalidRequestException e) {
            res.statusCode = 400;
            return e.getMessage();
        } catch (InvalidVendorCallKeyException e) {
            res.statusCode = 404;
            return e.getMessage();
        } catch (Exception e) {
            res.statusCode = 500;
            return e.getMessage();
        }
    }

    /**
     * @description Deletes a specific transcription
     * @param transcriptionDeleteRequest The request to delete a transcription
     */
    private static void deleteTranscript(TranscriptionDeleteRequest transcriptionDeleteRequest) {
        List<Id> conversationIds = new List<Id>();
        for (Conversation c : [
                SELECT Id
                FROM Conversation
                WHERE ConversationIdentifier = :transcriptionDeleteRequest.vendorCallKey
                WITH SECURITY_ENFORCED
        ]) {
            conversationIds.add(c.Id);
        }

        if (conversationIds.size() == 0) {
            throw new InvalidVendorCallKeyException('No conversation found with vendorCallKey: ' + transcriptionDeleteRequest.vendorCallKey);
        }

        List<ConversationEntry> conversationEntries = [
                SELECT Id
                FROM ConversationEntry
                WHERE ConversationId IN :conversationIds
                WITH SECURITY_ENFORCED
        ];

        Database.DeleteResult[] deleteResults = Database.delete(conversationEntries, false);

        String errorMessage = '';
        for (Database.DeleteResult deleteResult : deleteResults) {
            if (!deleteResult.isSuccess()) {
                for (Database.Error error : deleteResult.getErrors()) {
                    errorMessage += error.getMessage() + '\n';
                }
            }
        }

        if (errorMessage != '') {
            throw new DeleteException(errorMessage);
        }
    }

    /**
     * @description Represents a request to delete a transcription
     */
    private class TranscriptionDeleteRequest {
        public String vendorCallKey;

        /**
         * @description Constructor for the TranscriptionDeleteRequest class
         * @param jsonString The JSON string representing the delete request
         */
        public TranscriptionDeleteRequest(String jsonString) {
            Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(jsonString);
            vendorCallKey = (String) m.get('vendorCallKey');

            if (vendorCallKey == null) {
                throw new InvalidRequestException('vendorCallKey is required');
            }
        }
    }
}