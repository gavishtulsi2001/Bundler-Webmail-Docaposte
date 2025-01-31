/**
 * @description       : 
 * @author            : Gavish Varma Tulsi
 * @group             : 
 * @last modified on  : 01-30-2025
 * @last modified by  : Gavish Varma Tulsi
 * * @Version    
 * * Modifications Log
 *   Ver    Date         Author     Modification
 *   1.0    31-01-2024   GTL        Initial Version
 *   1.1    14-10-2024   JPA        PHE-1865
 *   1.2    23-01-2024   GTL        PHE-1751 / PHE-1754 / PHE-1942 / PHE-2064
**/
global with sharing class BAT76_DocaposteBatch implements Database.Batchable<SObject>, Database.AllowsCallouts, Database.RaisesPlatformEvents, Schedulable {
    private List<ServiceAppointment> lstValidServiceApp = new List<ServiceAppointment>();
    private List<ServiceAppointment> lstInvalidServiceApp = new List<ServiceAppointment>();
    private List<ServiceAppointment> lstSaToUpdate= new list<ServiceAppointment>();
    private List<ServiceAppointment> lstAllSaUpdt= new list<ServiceAppointment>();
    private String xmlString;
    private final String regEx = '^[^a-zA-Z0-9]+$';
    
    global BAT76_DocaposteBatch(){

    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        
        String queryCustom = Test.isRunningTest() ? 'NONE' : System.Label.BAT76_DocaposteBatch;

        Map<String, SOQL_Filter__mdt> mapSOQLFilter = SOQL_Filter__mdt.getAll();
        List<SOQL_Filter__mdt> lstFilter = new List<SOQL_Filter__mdt>();
        List<SOQL_Filter__mdt> lstComplexFilter = new List<SOQL_Filter__mdt>();
        List<SOQL_Filter__mdt> lstAdditionalFilter = new List<SOQL_Filter__mdt>();

        for (SOQL_Filter__mdt filter : mapSOQLFilter.values()) {
            if (filter.IsActive__c && filter.Batch__c == 'BAT76_DocaposteBatch') {
                if(filter.Filter_Type__c == 'ServiceTerritory.Name' || filter.Filter_Type__c == 'Service_Contract__r.Name' ){
                    lstComplexFilter.add(filter);
                }else if (filter.Filter_Type__c == 'WorkType.Name' || filter.Filter_Type__c == 'IsBundle' || filter.Filter_Type__c == 'BundlePolicy.Name' || filter.Filter_Type__c == 'Subject'){
                    lstAdditionalFilter.add(filter);
                }
                else{
                    lstFilter.add(filter);
                } 
            }
        }
        
        String dynamicFilter = AP_Constant.constructDynamicFilter(lstFilter);
        String complexFilter = constructComplexFilter(lstComplexFilter);
        String additionalFilter = constructAdditionalFilter(lstAdditionalFilter);

        string query =  'SELECT Id, ' +
                                'ServiceTerritory.Name, ' +
                                'ServiceTerritory.Agency_Code__c, ' +
                                'ServiceTerritory.Street, ' +
                                'ServiceTerritory.Street2__c, ' +
                                'ServiceTerritory.PostalCode, ' +
                                'ServiceTerritory.City, ' +
                                'ServiceTerritory.Country, ' +
                                'ServiceTerritory.Siret__c, ' +
                                'ServiceTerritory.Phone__c, ' +
                                'ServiceTerritory.Email__c, ' +
                                'Account.ClientNumber__c, ' +
                                'Account.Salutation, ' +
                                'Account.Name, ' +
                                'Account.BillingStreet, ' + 
                                'Account.BillingCity, ' +
                                'Account.BillingCountry, ' +
                                'Account.Adress_complement__c, ' + 
                                'Account.BillingPostalCode, ' +
                                'Account.BillingAddress, ' +
                                'Account.PersonEmail, ' +
                                'Account.Phone, ' +
                                'AppointmentNumber, ' + 
                                'SchedStartTime, ' +
                                'SchedEndTime, ' +
                                'Subject, ' +
                                'IsBundle, ' +
                                'BundlePolicy.Name, ' +
                                'WorkType.Name, ' +
                                'RelatedBundleId, ' +
                                //Inhabitant
                                'Residence__r.City__c, ' +
                                'Residence__r.Postal_Code__c, ' +
                                'Residence__r.Street__c, ' +
                                'Residence__r.Adress_Complement__c, ' +
                                'Residence__r.Inhabitant__r.Name, ' +
                                'Residence__r.Inhabitant__r.FirstName, ' +
                                'Residence__r.Inhabitant__r.LastName, ' +
                                'Residence__r.Inhabitant__r.Salutation, ' +
                                'Residence__r.Imm_Res__c, ' +
                                'Residence__r.Door__c, ' +
                                'Residence__r.Floor__c, ' +
                                'Residence__r.Inhabitant__r.RecordType.DeveloperName ,' +
                                'Residence__r.Inhabitant__r.PersonEmail, ' +
                                'Residence__r.Inhabitant__r.ClientNumber__c, ' +
                                'Residence__r.Inhabitant__r.PersonMobilePhone, ' +
                                //Owner
                                'Residence__r.Owner__r.BillingCity, ' +
                                'Residence__r.Owner__r.BillingPostalCode, ' +
                                'Residence__r.Owner__r.BillingStreet, ' +
                                'Residence__r.Owner__r.Adress_Complement__c, ' +
                                'Residence__r.Owner__r.Name, ' +
                                'Residence__r.Owner__r.FirstName, ' +
                                'Residence__r.Owner__r.LastName, ' +
                                'Residence__r.Owner__r.Salutation, ' +
                                'Residence__r.Owner__r.Imm_Res__c, ' +
                                'Residence__r.Owner__r.Door__c, ' +
                                'Residence__r.Owner__r.Floor__c, ' +
                                'Residence__r.Owner__r.RecordType.DeveloperName, ' +
                                'Residence__r.Owner__r.PersonEmail, ' +
                                'Residence__r.Owner__r.ClientNumber__c, ' +
                                'Residence__r.Owner__r.PersonMobilePhone, ' +
                                //Legal_Guardian
                                'Residence__r.Legal_Guardian__r.BillingCity, ' +
                                'Residence__r.Legal_Guardian__r.BillingPostalCode, ' +
                                'Residence__r.Legal_Guardian__r.BillingStreet, ' +
                                'Residence__r.Legal_Guardian__r.Adress_Complement__c, ' +
                                'Residence__r.Legal_Guardian__r.Name, ' +
                                'Residence__r.Legal_Guardian__r.FirstName, ' +
                                'Residence__r.Legal_Guardian__r.LastName, ' +
                                'Residence__r.Legal_Guardian__r.Salutation, ' +
                                'Residence__r.Legal_Guardian__r.Imm_Res__c, ' +
                                'Residence__r.Legal_Guardian__r.Door__c, ' +
                                'Residence__r.Legal_Guardian__r.Floor__c, ' +
                                'Residence__r.Legal_Guardian__r.RecordType.DeveloperName, ' +
                                'Residence__r.Legal_Guardian__r.PersonEmail, ' +
                                'Residence__r.Legal_Guardian__r.ClientNumber__c, ' +
                                'Residence__r.Legal_Guardian__r.PersonMobilePhone, ' +
                                //Account
                                'Residence__r.Account__r.BillingCity, ' +
                                'Residence__r.Account__r.BillingPostalCode, ' +
                                'Residence__r.Account__r.BillingStreet, ' +
                                'Residence__r.Account__r.Adress_Complement__c, ' +
                                'Residence__r.Account__r.Name, ' +
                                'Residence__r.Account__r.FirstName, ' +
                                'Residence__r.Account__r.LastName, ' +
                                'Residence__r.Account__r.Salutation, ' +
                                'Residence__r.Account__r.Imm_Res__c, ' +
                                'Residence__r.Account__r.Door__c, ' +
                                'Residence__r.Account__r.Floor__c, ' +
                                'Residence__r.Account__r.RecordType.DeveloperName, ' +
                                'Residence__r.Account__r.PersonEmail, ' +
                                'Residence__r.Account__r.ClientNumber__c, ' +
                                'Residence__r.Account__r.PersonMobilePhone, ' +
                                'Contact.Name, ' +
                                'Contact.Salutation, ' +
                                'ServiceTerritory.TerritoryStat__c, ' +
                                'ServiceTerritory.Corporate_Name__c, ' +
                                'Residence__r.Visit_Notice_Recipient__c, ' +
                                'Service_Contract__r.RecordType.DeveloperName, ' +
                                'ServiceTerritory.Sofactoapp_Raison_Social__r.sofactoapp_Agence__r.Corporate_Name__c, ' +
                                'ServiceTerritory.Sofactoapp_Raison_Social__r.sofactoapp_Agence__r.Legal_Form__c, ' +
                                'ServiceTerritory.Sofactoapp_Raison_Social__r.sofactoapp_Agence__r.Capital_in_Eur__c, ' +
                                'ServiceTerritory.Sofactoapp_Raison_Social__r.sofactoapp_Agence__r.Corporate_Street__c, ' +
                                'ServiceTerritory.Sofactoapp_Raison_Social__r.sofactoapp_Agence__r.Corporate_Street2__c, ' +
                                'ServiceTerritory.Sofactoapp_Raison_Social__r.sofactoapp_Agence__r.Corporate_ZipCode__c, ' +
                                'ServiceTerritory.Sofactoapp_Raison_Social__r.sofactoapp_Agence__r.Siren__c, ' +
                                'ServiceTerritory.Sofactoapp_Raison_Social__r.sofactoapp_Agence__r.Corporate_City__c, ' +
                                'ServiceTerritory.Sofactoapp_Raison_Social__r.sofactoapp_Agence__r.RCS__c, ' +
                                'ArrivalWindowEndTime, ' +
                                'ServiceTerritory.Sofactoapp_Raison_Social__r.Name, ' +
                                'Service_Contract__r.Logement__r.Inhabitant__r.PersonEmail, '+
                                'ServiceTerritory.Sofactoapp_Raison_Social__r.sofactoapp__Forme_juridique__c, ' +
                                'ServiceTerritory.Sofactoapp_Raison_Social__r.sofactoapp__Capital_social__c, ' +
                                'ServiceTerritory.Sofactoapp_Raison_Social__r.Sofacto_Adresse_Agence_2__c, ' +
                                'ServiceTerritory.Sofactoapp_Raison_Social__r.sofactoapp__RueFactu__c, ' +
                                'ServiceTerritory.Sofactoapp_Raison_Social__r.sofactoapp__Code_postal__c, ' +
                                'ServiceTerritory.Sofactoapp_Raison_Social__r.sofactoapp__Ville__c, ' +
                                'ServiceTerritory.Sofactoapp_Raison_Social__r.sofactoapp__SIREN__c, ' +
                                'ServiceTerritory.Sofactoapp_Raison_Social__r.sofactoapp__Ville_RCS__c, ' +
                                'Service_Contract__r.RecordType.Name, ' +
                                'Service_Contract__r.Account.ClientNumber__c, ' +
                                'ServiceTerritory.Sofactoapp_Raison_Social__r.sofactoapp__Rue__c, ' +
                                'ServiceTerritoryId  ' +
                            'FROM ServiceAppointment ';
        
        if(queryCustom!='NONE'){
            query += queryCustom;
        }else{
            query += ' WHERE (Status = \'Scheduled\' OR Status = \'Dispatched\') ';
            query += dynamicFilter;
            query += complexFilter; 
            query += additionalFilter;
            // query += ' WHERE Id = \'08pAU000000yF93YAE\' ';
        }

        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<ServiceAppointment> lstSA) {
        Map<Id, ServiceAppointment> IdbyValidServApp = new Map<Id, ServiceAppointment>();
        String fileName='';

        for (ServiceAppointment sa : lstSA) {                                                    
            Map<String, Boolean> mapValidationResults = isValidServiceAppointment(sa);
            if (mapValidationResults.get('Aucune')) {
                IdbyValidServApp.put(sa.Id, sa);
                lstValidServiceApp.add(sa);
            } else {
                mapValidationResults.remove('Aucune');
                String exclusionReasons = String.join(new List<String>(mapValidationResults.keySet()), '; ');
                sa.RaisonExclusion__c = exclusionReasons;
                lstInvalidServiceApp.add(sa);
            }
        }

        if (!lstValidServiceApp.isEmpty()) {
            Map<String, Set<Id>> xmlStringMap = AP93_DocaposteXMLGenerator.GenerateXML(lstValidServiceApp);
            Set<Id> setSaId = new Set<Id>();
            for (String key : xmlStringMap.keySet()) {
                xmlString = key;
                setSaId.addAll(xmlStringMap.get(key));
            }

            Set<Id> relatedBundleId = new Set<Id>();
            for(ServiceAppointment sa: lstValidServiceApp){
                if(sa.IsBundle && sa.BundlePolicy.Name == 'ABP - Plusieurs équipements' && sa.Subject.toLowerCase().contains('entretien')){
                    relatedBundleId.add(sa.Id);
                }
            }
    
            Map<Id,List<ServiceAppointment>> idByServApp = new map<Id,List<ServiceAppointment>>();
    
            for(ServiceAppointment sa: [SELECT Id,
                                            RelatedBundleId,
                                            IsBundle,
                                            Service_Contract__r.RecordType.DeveloperName,
                                            Residence__r.Inhabitant__r.PersonEmail,
                                            Residence__r.Owner__r.PersonEmail,
                                            Residence__r.Legal_Guardian__r.PersonEmail,
                                            Residence__r.Account__r.PersonEmail,
                                            Service_Contract__r.Account.ClientNumber__c,
                                            Account.ClientNumber__c
                                        FROM 
                                            ServiceAppointment
                                        WHERE
                                            RelatedBundleId IN: relatedBundleId])
            {
                if (!idByServApp.containsKey(sa.RelatedBundleId)) {
                    idByServApp.put(sa.RelatedBundleId, new List<ServiceAppointment>{ sa });
                } else {
                    idByServApp.get(sa.RelatedBundleId).add(sa);
                }
            }
    
            if (!setSaId.isEmpty()) {
                Map<String,String> mapReturnedVal = AP93_POCDocaposte.accessingTheWebservice(xmlString);

                string message = mapReturnedVal.get('msg');
                fileName = mapReturnedVal.get('filename');
                
                for (id saId : setSaId) {
                    ServiceAppointment updatedSa = new ServiceAppointment(
                        Id = saId,
                        Tech_Doca_Webservice__c = message,
                        RaisonExclusion__c = 'Aucune'
                       
                    );

                    if (message.contains('820')) {
                        updatedSa.Tech_AVP__c = System.now();
                        updatedSa.Visit_Notice_Generated_In_Mass__c = true;
                        updatedSa.Tech_Envoi_Webmail__c = isServiceAppointmentEnvoiMail(IdbyValidServApp.get(saId), idByServApp);
                    }

                    lstSaToUpdate.add(updatedSa);
                }
            }
        }
        
        if(!lstSaToUpdate.isEmpty()){
            lstAllSaUpdt.addALl(lstSaToUpdate);
        }

        if(!lstInvalidServiceApp.isEmpty()){
            lstAllSaUpdt.addAll(lstInvalidServiceApp);
        }
        
        if(!lstAllSaUpdt.isEmpty()){
            System.enqueueJob(new AP93_DMLQueueable(xmlString, lstAllSaUpdt, fileName));
        }
    }

    global void finish(Database.BatchableContext BC) {

    }

    private Map<String, Boolean> isValidServiceAppointment(ServiceAppointment sa) {
        Map<String, Boolean> mapValidationResults = new Map<String, Boolean>();
        Boolean isValid = true;
        List<String> inappropriateNames = new List<String>{'VIDE', 'VMC', 'Caisson', 'VACANT', 'Extracteur', 'VACCANT'};

        if(String.isBlank(sa.ServiceTerritory.Agency_Code__c)){
            mapValidationResults.put('Code de l\'agence manquant', false);
            isValid = false;
        }
       
        //Inhabitant 
        if(sa.Residence__r.Visit_Notice_Recipient__c == 'Inhabitant'){
            if(
                (sa.Residence__r?.Inhabitant__r?.RecordType?.DeveloperName == AP_Constant.businessAcc && (Utils.checkRegex(regEx, sa.Contact.Name)|| String.isBlank(sa.Contact.Name))) ||
                (sa.Residence__r?.Inhabitant__r?.RecordType?.DeveloperName != AP_Constant.businessAcc && (Utils.checkRegex(regEx, sa.Residence__r.Inhabitant__r.Name)||String.isBlank(sa.Residence__r.Inhabitant__r.Name)))
            ){
                mapValidationResults.put('Nom de l\'occupant manquant', false);
                isValid = false;
            }
            
            
            if(String.isBlank(sa.Residence__r.City__c)){
                mapValidationResults.put('Ville de l\'occupant manquante', false);
                isValid = false;
            }
    
            if(String.isBlank(sa.Residence__r.Postal_Code__c)){
                mapValidationResults.put('Code postal de l\'occupant manquant', false);
                isValid = false;
            }
    
            if(!checkPostalCode(sa.Residence__r.Postal_Code__c)){
                mapValidationResults.put('Code postal de l\'occupant invalide', false);
                isValid = false;
            }

            if(
                (String.isBlank(sa.Residence__r.Street__c) && String.isBlank(sa.Residence__r?.Adress_Complement__c)) || 
                (Utils.checkRegex(regEx, sa.Residence__r.Street__c)  && Utils.checkRegex(regEx, sa.Residence__r?.Adress_Complement__c))
            ){
                mapValidationResults.put('Lignes d\'adresse de l\'occupant manquantes', false);
                isValid = false;
            }

            if((sa.Residence__r?.Inhabitant__r?.RecordType?.DeveloperName != AP_Constant.businessAcc && containsIgnoreCase(sa.Residence__r?.Inhabitant__r?.Name, inappropriateNames))
            ){
                mapValidationResults.put('Nom de l\'occupant inapproprié', false);
                isValid = false;
            }

        }
        
        //Owner
        if(sa.Residence__r.Visit_Notice_Recipient__c == 'Owner'){
            if(
                (sa?.Residence__r?.Owner__r?.RecordType?.DeveloperName == AP_Constant.businessAcc && (Utils.checkRegex(regEx, sa.Contact.Name)|| String.isBlank(sa.Contact.Name) )) ||
                (sa?.Residence__r?.Owner__r?.RecordType?.DeveloperName != AP_Constant.businessAcc && (Utils.checkRegex(regEx, sa.Residence__r.Owner__r.Name)||String.isBlank(sa.Residence__r.Owner__r.Name)))
            )
            {
                mapValidationResults.put('Nom de l\'occupant manquant', false);
                isValid = false;
            }
            
            if(String.isBlank(sa.Residence__r.Owner__r.BillingCity)){
                mapValidationResults.put('Ville de l\'occupant manquante', false);
                isValid = false;
            }
    
            if(String.isBlank(sa.Residence__r.Owner__r.BillingPostalCode)){
                mapValidationResults.put('Code postal de l\'occupant manquant', false);
                isValid = false;
            }
    
            if(!checkPostalCode(sa.Residence__r.Owner__r.BillingPostalCode)){
                mapValidationResults.put('Code postal de l\'occupant invalide', false);
                isValid = false;
            }
           
            if((String.isBlank(sa.Residence__r.Owner__r.BillingStreet) && String.isBlank((sa.Residence__r.Owner__r.Adress_Complement__c)))
            ||(Utils.checkRegex(regEx, sa.Residence__r.Owner__r.BillingStreet) && Utils.checkRegex(regEx, sa.Residence__r.Owner__r.Adress_Complement__c))){
                mapValidationResults.put('Lignes d\'adresse de l\'occupant manquantes', false);
                isValid = false;
            }

            if((sa?.Residence__r?.Owner__r?.RecordType?.DeveloperName != AP_Constant.businessAcc && containsIgnoreCase(sa?.Residence__r?.Owner__r?.Name, inappropriateNames))
            ){
                mapValidationResults.put('Nom de l\'occupant inapproprié', false);
                isValid = false;
            }
            
        }
    
        //Legal Guardian
        if(sa.Residence__r.Visit_Notice_Recipient__c == 'Legal Guardian'){

            if(
                (sa?.Residence__r?.Legal_Guardian__r?.RecordType?.DeveloperName == AP_Constant.businessAcc && (Utils.checkRegex(regEx, sa.Contact.Name)|| String.isBlank(sa.Contact.Name) )) ||
                (sa?.Residence__r?.Legal_Guardian__r?.RecordType?.DeveloperName != AP_Constant.businessAcc && (Utils.checkRegex(regEx, sa.Residence__r.Legal_Guardian__r.Name)||String.isBlank(sa.Residence__r.Legal_Guardian__r.Name)))
            )
            {
                mapValidationResults.put('Nom de l\'occupant manquant', false);
                isValid = false;
            }
            
            if(String.isBlank(sa.Residence__r.Legal_Guardian__r.BillingCity)){
                mapValidationResults.put('Ville de l\'occupant manquante', false);
                isValid = false;
            }
    
            if(String.isBlank(sa.Residence__r.Legal_Guardian__r.BillingPostalCode)){
                mapValidationResults.put('Code postal de l\'occupant manquant', false);
                isValid = false;
            }
    
            if(!checkPostalCode(sa.Residence__r.Legal_Guardian__r.BillingPostalCode)){
                mapValidationResults.put('Code postal de l\'occupant invalide', false);
                isValid = false;
            }

            if(
                (String.isBlank(sa.Residence__r.Legal_Guardian__r.BillingStreet) && String.isBlank((sa.Residence__r.Legal_Guardian__r.Adress_Complement__c)))||
                (Utils.checkRegex(regEx, sa.Residence__r.Legal_Guardian__r.BillingStreet) && Utils.checkRegex(regEx, sa.Residence__r.Legal_Guardian__r.Adress_Complement__c))
            ){
                mapValidationResults.put('Lignes d\'adresse de l\'occupant manquantes', false);
                isValid = false;
            }

            if((sa?.Residence__r?.Legal_Guardian__r?.RecordType?.DeveloperName != AP_Constant.businessAcc && containsIgnoreCase(sa?.Residence__r?.Legal_Guardian__r?.Name, inappropriateNames))
            ){
                mapValidationResults.put('Nom de l\'occupant inapproprié', false);
                isValid = false;
            }
            
        }

        //Administrator
        if(sa.Residence__r.Visit_Notice_Recipient__c == 'Administrator'){
            
            if(
                (sa.Residence__r?.Account__r?.RecordType?.DeveloperName == AP_Constant.businessAcc && (Utils.checkRegex(regEx, sa.Contact.Name)|| String.isBlank(sa.Contact.Name) )) ||
                (sa.Residence__r?.Account__r?.RecordType?.DeveloperName != AP_Constant.businessAcc && (Utils.checkRegex(regEx,sa.Residence__r.Account__r.Name)||String.isBlank(sa.Residence__r.Account__r.Name)))
            )
            {
                mapValidationResults.put('Nom de l\'occupant manquant', false);
                isValid = false;
            }
            
            if(String.isBlank(sa.Residence__r.Account__r.BillingCity)){
                mapValidationResults.put('Ville de l\'occupant manquante', false);
                isValid = false;
            }
    
            if(String.isBlank(sa.Residence__r.Account__r.BillingPostalCode)){
                mapValidationResults.put('Code postal de l\'occupant manquant', false);
                isValid = false;
            }
    
            if(!checkPostalCode(sa.Residence__r.Account__r.BillingPostalCode)){
                mapValidationResults.put('Code postal de l\'occupant invalide', false);
                isValid = false;
            }

            if(
                (String.isBlank(sa.Residence__r.Account__r.BillingStreet) && String.isBlank((sa.Residence__r.Account__r.Adress_Complement__c))) ||
                (Utils.checkRegex(regEx, sa.Residence__r.Account__r.BillingStreet) && Utils.checkRegex(regEx, sa.Residence__r.Account__r.Adress_Complement__c))
            ){ 
                mapValidationResults.put('Lignes d\'adresse de l\'occupant manquantes', false);
                isValid = false;
            }

            if((sa?.Residence__r?.Account__r?.RecordType?.DeveloperName != AP_Constant.businessAcc && containsIgnoreCase(sa?.Residence__r?.Account__r?.Name, inappropriateNames))
            ){
                mapValidationResults.put('Nom de l\'occupant inapproprié', false);
                isValid = false;
            }
            
        }


        if(String.isBlank(sa.ServiceTerritory.Phone__c)){
            mapValidationResults.put('Numéro de téléphone de l\'agence manquant', false);
            isValid = false;
        }

        if(String.isBlank(sa.ServiceTerritory.Email__c)){
            mapValidationResults.put('Email de l\'agence manquant', false);
            isValid = false;
        }    

        mapValidationResults.put('Aucune', isValid);
        return mapValidationResults;
    }

    public static Boolean checkPostalCode(String codePostal){
        codePostal = removeExtraSpaces(codePostal);
        Pattern myPattern = Pattern.compile('^[0-9]+$');
        if(codePostal==null){
            return false;
        }else{
            Matcher myMatcher = myPattern.matcher(codePostal);
            if(!myMatcher.matches()){
                return false;
            }else{
                if(codePostal.length() == 5){
                    return true;
                }else{
                    return false;
                }
                
            }
        }
    }
    public static String removeExtraSpaces(String input) {
        if (input == null) {
            return null;
        }

        String trimmedInput = input.trim();
        String result = trimmedInput.replaceAll(' ', '');

        return result;
    }

    public static String constructComplexFilter(List<SOQL_Filter__mdt> lstComplexFilter) {
        Map<String, String> fieldValuesMap = new Map<String, String>();
        for (SOQL_Filter__mdt filter : lstComplexFilter) {
            fieldValuesMap.put(filter.Filter_Type__c, filter.Filter_Value__c);
        }
        
        String territoryField = 'ServiceTerritory.Name';
        String contractField = 'Service_Contract__r.Name';
        String territoryValues = fieldValuesMap.get(territoryField);
        String contractValues = fieldValuesMap.get(contractField);

        List<String> notTerritoryClauses = new List<String>();

        for(String territoryValue: territoryValues.split(',')){
            String notTerritoryClause = AP_Constant.constructLikeClause(territoryField, territoryValue, true);
            String contractClause = AP_Constant.constructLikeClause(contractField, contractValues, false);
            String modifiednotTerritoryClause = notTerritoryClause.substring(0, notTerritoryClause.length() - 3);
            String complexFilter = modifiednotTerritoryClause + contractClause + '))';
            notTerritoryClauses.add(complexFilter);
        }

        String combinedNotTerritoryClauses = String.join(notTerritoryClauses, '');        

        return combinedNotTerritoryClauses;
    }

    public static String constructAdditionalFilter(List<SOQL_Filter__mdt> lstAdditionalFilter) {
        Map<String, String> fieldValuesMap = new Map<String, String>();
        for (SOQL_Filter__mdt filter : lstAdditionalFilter) {
            fieldValuesMap.put(filter.Filter_Type__c, filter.Filter_Value__c);
        }
    
        List<String> workTypeClause = new List<String>();
        String bundleClause = '';
        List<String> combineWrkTypeBundleClause = new List<String>();

        if (fieldValuesMap.containsKey('WorkType.Name')) {
            String clause = AP_Constant.constructLikeClause('WorkType.Name', fieldValuesMap.get('WorkType.Name'), false);
            workTypeClause.add(clause.replace('AND ', '').trim());
        }
    
        if (fieldValuesMap.containsKey('IsBundle') && fieldValuesMap.containsKey('BundlePolicy.Name') && fieldValuesMap.containsKey('Subject')) {
            String isBundleField = 'IsBundle';
            String bundlePolicyField = 'BundlePolicy.Name';
            String subjectField = 'Subject';
            String isBundleValues = fieldValuesMap.get(isBundleField);
            String bundlePolicyValues = fieldValuesMap.get(bundlePolicyField);
            String subjectValues = fieldValuesMap.get(subjectField);

            String isBundleClause = AP_Constant.constructEqualClause(isBundleField, isBundleValues, false).replace('AND ', '').trim();
            String bundleNameClause = AP_Constant.constructEqualClause('BundlePolicy.Name', bundlePolicyValues, true).replace('AND ', '').trim();
            String subjectClause = AP_Constant.constructLikeClause(subjectField, subjectValues, false).replace('AND ', '').trim();
            bundleClause = '(' + isBundleClause + ' AND ' + bundleNameClause   + ' AND ' + subjectClause + ')';
        }

        if(!workTypeClause.isEmpty()){
            combineWrkTypeBundleClause.add('(' + String.join(workTypeClause, ' OR ') + ')');
        }

        if(String.isNotBlank(bundleClause)){
            combineWrkTypeBundleClause.add(bundleClause);
        }
    
        return combineWrkTypeBundleClause.isEmpty() ? '' : 'AND (' + String.join(combineWrkTypeBundleClause, ' OR ') + ')';
    }
    

    //Check Envoi Mail or Envoi Edit(Tech_Envoi_Webmail__c)
    private Boolean isServiceAppointmentEnvoiMail(ServiceAppointment sa, Map<Id, List<ServiceAppointment>> idByServApp) {
        Set<Id> relatedBundleId = new Set<Id>();
        if(relatedBundleId.contains(sa.Id)){
            List<ServiceAppointment> relatedSA = idByServApp.get(sa.Id);
            
            if(!relatedSA.isEmpty()){
                ServiceAppointment firstSA = relatedSA[0];
                if (firstSA?.Service_Contract__r != null && firstSA?.Service_Contract__r?.RecordType?.DeveloperName == AP_Constant.ContratsCollectifPublic) {
                    return false;
                } else {
                    if (
                        (String.isNotBlank(firstSA.Residence__r?.Inhabitant__r?.PersonEmail) && firstSA.Residence__r.Visit_Notice_Recipient__c == 'Inhabitant') ||
                        (String.isNotBlank(firstSA.Residence__r?.Owner__r?.PersonEmail) && firstSA.Residence__r.Visit_Notice_Recipient__c == 'Owner') ||
                        (String.isNotBlank(firstSA.Residence__r?.Legal_Guardian__r?.PersonEmail) && firstSA.Residence__r.Visit_Notice_Recipient__c == 'Legal Guardian') ||
                        (String.isNotBlank(firstSA.Residence__r?.Account__r?.PersonEmail) && firstSA.Residence__r.Visit_Notice_Recipient__c == 'Administrator')
                    ) {
                        return true;
                    } else {
                        return false;
                    }
                }
                
            }else{
                return false;
            }
        }else{
            
            if (sa?.Service_Contract__r != null && sa?.Service_Contract__r?.RecordType?.DeveloperName == AP_Constant.ContratsCollectifPublic) {
                return false;
            } else {
                if (
                    (String.isNotBlank(sa.Residence__r?.Inhabitant__r?.PersonEmail) && sa.Residence__r.Visit_Notice_Recipient__c == 'Inhabitant') ||
                    (String.isNotBlank(sa.Residence__r?.Owner__r?.PersonEmail) && sa.Residence__r.Visit_Notice_Recipient__c == 'Owner') ||
                    (String.isNotBlank(sa.Residence__r?.Legal_Guardian__r?.PersonEmail) && sa.Residence__r.Visit_Notice_Recipient__c == 'Legal Guardian') ||
                    (String.isNotBlank(sa.Residence__r?.Account__r?.PersonEmail) && sa.Residence__r.Visit_Notice_Recipient__c == 'Administrator')
                ) {
                    return true;
                } else {
                    return false;
                }
            }
        }
    }
    
    private Boolean containsIgnoreCase(String target, List<String> values) {
        for (String value : values) {
            if (target != null && target.toLowerCase().contains(value.toLowerCase())) {
                return true;
            }
        }
        return false;
    }

	global static String scheduleBatch() {
		BAT76_DocaposteBatch scheduler = new BAT76_DocaposteBatch();
		return System.schedule('BAT76_DocaposteBatch:' + Datetime.now().format(), '0 0 21 * * ?', scheduler);
	}

	global void execute(SchedulableContext sc) {
		batchConfiguration__c batchConfig = batchConfiguration__c.getValues('BAT76_DocaposteBatch');

		if (batchConfig != null && batchConfig.BatchSize__c != null) {
			Database.executeBatch(new BAT76_DocaposteBatch(), Integer.valueof(batchConfig.BatchSize__c));
		} else {
			Database.executeBatch(new BAT76_DocaposteBatch(), 200);
		}
	}

}