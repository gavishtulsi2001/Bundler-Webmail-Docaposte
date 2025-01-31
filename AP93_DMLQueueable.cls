/**
 * @description       : 
 * @author            : JPA
 * @group             : 
 * @last modified on  : 15-11-2024
 * @last modified by  : JPA
**/
global with sharing class AP93_DMLQueueable  implements Queueable {

    private List<ServiceAppointment> lstSA;
    private String xml;
    private List<TransactionLog__c> lstTransLog= new list<TransactionLog__c>(); 
    private String fileName;


    public AP93_DMLQueueable(String xml, List<ServiceAppointment> lstSA, String fileName) {
        this.xml = xml;
        this.lstSA = lstSA;
        this.fileName = fileName;
    }
  
    
    public void execute(QueueableContext context) {

        if (!this.lstSA.isEmpty()) {
            List<Database.SaveResult> lstSaResult = Database.update(this.lstSA, false);
            handleErrors(lstSaResult, this.lstSA, lstTransLog, 'BAT76_DocaposteBatch');
        }

        if (!lstTransLog.isEmpty()) {
            Database.insert(lstTransLog, false);
        }

        if(!String.isBlank(this.xml)){
            generateDocument(this.xml);
        }
    }

    public void handleErrors(List<Database.SaveResult> lstSaResult, List<ServiceAppointment> lstSA, List<TransactionLog__c> lstTransLog, String processName) {
        for (Integer i = 0; i < lstSA.size(); i++) {
            Database.SaveResult sr = lstSaResult[i];
            if (!sr.isSuccess()) {
                TransactionLog__c transLog = new TransactionLog__c(
                    ProcessName__c = processName,
                    RecordId__c = lstSA[i].Id,
                    Message__c = sr.getErrors().get(0).getMessage()
                );
                lstTransLog.add(transLog);
            }
        }
    }

    public  void generateDocument(String xml){
        
        // String fileName = AP_Constant.generateName('DocaposteXML','.xml');
        ContentVersion content = new ContentVersion();
        content.Title = this.fileName;
        content.PathOnClient = this.fileName;
        content.VersionData = Blob.valueof(xml);
        content.ContentLocation = 's';
        insert content;
        

        content = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :content.Id LIMIT 1];
        ContentDocument conDoc = new ContentDocument(Id = content.ContentDocumentId);

        List<ContentWorkspace> lstWs = [SELECT Id, RootContentFolderId FROM ContentWorkspace WHERE Name LIKE '%DocaposteXmlFile%' LIMIT 1];
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = content.ContentDocumentId;
        cdl.ShareType = 'I';
        cdl.Visibility = 'AllUsers';
        cdl.LinkedEntityId = lstWs[0].Id;
        insert cdl;
    }
}