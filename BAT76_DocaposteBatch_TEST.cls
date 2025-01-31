/**
 * @description       : 
 * @author            : Gavish Varma Tulsi
 * @group             : 
 * @last modified on  : 06-18-2024
 * @last modified by  : Gavish Varma Tulsi
**/
@isTest
public with sharing class BAT76_DocaposteBatch_TEST {
    static User mainUser;
    static User serviceTerrUser;
    static Account testAcc = new Account();
    static Account testAcc2 = new Account();
    static List<Case> lstCases;
    static List<WorkOrder> lstWOs;
    static List<ServiceAppointment> lstSAs;
    static List<AssignedResource> lstAR= new list<AssignedResource>();  
    static List<ServiceResource> lstServResource=new List<ServiceResource>();   
    static Logement__c logement1 = new Logement__c();
    static ServiceTerritory agence1 = new ServiceTerritory();
    static ServiceTerritory agence2 = new ServiceTerritory();
    static ServiceContract contract = new ServiceContract();
    
    static{
            mainUser = TestFactory.createAdminUser('BAT76_DocaposteBatch@test.com', TestFactory.getProfileAdminId());
            mainUser.companyName = 'Coutances';
            insert mainUser;
            serviceTerrUser = TestFactory.createAdminUser('serviceTerr@test.com', TestFactory.getProfileAdminId());
            mainUser.companyName = 'Coutances';
            serviceTerrUser.phone='0612345678';
            insert serviceTerrUser;
            Bypass__c userBypass = Bypass__c.getInstance(mainUser.Id);

            userBypass.BypassValidationRules__c = true;
            userBypass.BypassTrigger__c='AP46 , AP17_FSLScheduleServiceAppointment, AP84';
            userBypass.BypassWorkflows__c=true;
            userbypass.Bypass_Flow__c=true;
            userBypass.Bypass_Process_Builder__c = true;
            insert userBypass;

            System.runAs(mainUser){

            //Create Account
            testAcc = TestFactory.createAccount('Test Acc');
            testAcc.BillingPostalCode = '75001';
            testAcc.Phone = '1234567890';
            testAcc.FirstName = 'Test Acc';
            testAcc.PersonEmail = 'test@iziconfort.fr';
            testAcc.Type = 'Particulier';
            testAcc.recordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
            insert testAcc;

            testAcc2 = TestFactory.createAccountBusiness('Test Acc');
            testAcc2.BillingPostalCode = '75001';
            testAcc2.Phone = '1234567890';
            insert testAcc2;

            Contact con = new Contact();
            con.FirstName= 'jashveer';
            con.lastName= 'patron';
			con.AccountId = testAcc2.Id;
            con.Salutation = 'Mr';
			insert con;

            List<Account> lstAcc = [SELECT Id, BillingPostalCode, Name, PersonEmail, Phone FROM Account WHERE Id =: testAcc.Id];
            System.debug('testAcc' +lstAcc);

            //Create operating hour
            OperatingHours newOperatingHour = TestFactory.createOperatingHour('test1');
            insert newOperatingHour;
            agence2 = TestFactory.createServiceTerritory('test agence england s', newOperatingHour.Id);
            //agence1.Name = mainUser.companyName;
            agence2.Name ='test agence england';
            agence2.Agency_Code__c = '7002';
            agence2.email__c='england@test.com';
            agence2.phone__c='0612345679';
            agence2.Corporate_Street__c = 'england';
            agence2.Corporate_Street2__c = 'england';

            insert agence2;

            //create sofacto
            sofactoapp__Raison_Sociale__c sofa = new sofactoapp__Raison_Sociale__c(Name= 'TEST', sofactoapp__Credit_prefix__c= '234', sofactoapp__Invoice_prefix__c='432',sofactoapp__Liste_pays__c='Maurice', sofactoapp__Forme_juridique__c = 'SASU',sofactoapp__Capital_social__c = 5861600 );
            sofa.sofactoapp__RueFactu__c='test123';
            sofa.sofactoapp__Rue__c='test123';
            sofa.sofactoapp__Code_postal__c='75001';
            sofa.sofactoapp__Ville__c='Paris';
            sofa.sofactoapp__SIREN__c='';
            sofa.sofactoapp__Ville_RCS__c='';
            sofa.sofactoapp_Agence__c=agence2.id;
            sofa.sofactoapp__Forme_juridique__c='SAS';
            sofa.sofactoapp__Capital_social__c=700000;
            sofa.Sofacto_Adresse_Agence_2__c='Test';
            sofa.sofactoapp__RueFactu__c='test address';
            insert sofa;
            
            //Create Agence
            agence1 = TestFactory.createServiceTerritory('test agence paris s', newOperatingHour.Id, sofa.Id);
            //agence1.Name = mainUser.companyName;
            agence1.Name ='test agence paris';
            agence1.Agency_Code__c = '7001';
            agence1.email__c='testAgency@test.com';
            agence1.phone__c='0612345678';

            // agence1.Sofactoapp_Raison_Social__c= sofa.id;
            insert agence1;

            //Create Logement
            logement1 = TestFactory.createLogement(testAcc.Id, agence1.Id);
            logement1.Inhabitant__c=testAcc.Id;
            logement1.City__c = 'paris';
            logement1.Postal_Code__c = '70001';
            logement1.Visit_Notice_Recipient__c = 'Inhabitant';
            insert logement1;
            

            List<Product2> lstTestProd = new List<Product2>{TestFactory.createProductAsset('testProduit') , TestFactory.createProductAsset('testProduit2'),TestFactory.createProductAsset('testProduit3')};
            insert lstTestProd;

            Id id = Test.getstandardpricebookid();

            PricebookEntry priceBookEntry = new PricebookEntry(UseStandardPrice = false , Pricebook2Id = id, IsActive = true,Product2Id = lstTestProd[0].Id, UnitPrice = 1000 );
            insert priceBookEntry;
             
            // Create Asset
            Asset myAsset = TestFactory.CreateAsset('Equipment 1', AP_Constant.assetStatusActif, logement1.Id);
            myAsset.AccountId = testAcc.Id;

            //Create Service Contract
            contract = new ServiceContract(	AccountId = testAcc.Id, Pricebook2Id = id, Agency__c = agence1.Id,Name = 'V0 Service Contract', Asset__c = myAsset.Id ,Contract_Renewed__c = true,Contract_Status__c = 'Active' );
            insert contract;

            WorkType workType = new WorkType(Name = 'WorkType entretien s' ,EstimatedDuration = 45 ,DurationType = 'Minutes',Type__c = 'Maintenance', Equipment_type__c = 'Chaudière gaz');
            insert workType;
            
            myAsset.Product2Id = lstTestProd[0].Id;
            insert myAsset;
            
            //Create list of Cases
            Case case1 = TestFactory.createCase(testAcc.Id, 'Claim',  myAsset.Id);
            case1.Service_Contract__c = contract.Id;
            Case case2 = TestFactory.createCase(testAcc.Id, 'Installation', myAsset.Id);
            case2.Service_Contract__c = contract.Id;
            Case case3 = TestFactory.createCase(testAcc.Id, 'Maintenance', myAsset.Id);
            case3.Service_Contract__c = contract.Id;
            
            lstCases = new List<Case>{
            case1,
            case2,
            case3
            };

            insert lstCases;

            //Create list of Work Orders
            WorkOrder workorder1 = TestFactory.CreateWorkOrder();
            workorder1.CaseId = case1.Id;
            workorder1.AccountId = testAcc.Id;
            WorkOrder workorder2 = TestFactory.CreateWorkOrder();
            workorder2.CaseId = case2.Id;
            workorder2.AccountId = testAcc.Id;
            WorkOrder workorder3 = TestFactory.CreateWorkOrder();
            workorder3.CaseId = case3.Id;
            workorder3.AccountId = testAcc.Id;

            lstWOs = new List<WorkOrder>{
                workorder1,
                workorder2,
                workorder3
            };

            insert lstWOs;

            
            //Create list of Service Appointments
            ServiceAppointment servApp1 = TestFactory.createServiceAppointment(workorder3.Id);
            servApp1.Category__c = 'VE Individuelle';
            servApp1.Status = 'Scheduled';
            servApp1.VE_Planning__c = false;
            servApp1.ServiceTerritoryId = agence1.Id;

            servApp1.EarliestStartTime = Date.newInstance(2020,03,01);
            servApp1.DueDate = Date.newInstance(2024,03,31);
            servApp1.Work_Order__c=lstWOs[2].id;
            servApp1.WorkTypeId = workType.Id;
            //servApp1.BundlePolicyId = '7sTSb0000000002MAA';
            servApp1.IsBundleMember = false;
            servApp1.TECH_AVP__c = null;
            servApp1.schedStartTime = DateTime.now().addDays(15);
            servApp1.SchedEndTime = DateTime.now().addDays(30);
            servApp1.Service_Contract__c = contract.Id;
            servApp1.ParentRecordId = workorder3.Id;
            servApp1.ContactId =  testAcc.PersonContactId;
            servApp1.ActualStartTime = system.today();
            servApp1.Residence__c=logement1.id;
            // servApp1.contact=con;
            ServiceAppointment servApp2 = TestFactory.createServiceAppointment(workorder2.Id);
            servApp2.Category__c = 'VE Individuelle';
            servApp2.Status = 'Scheduled';
            servApp2.VE_Planning__c = false;
            servApp2.ServiceTerritoryId = agence1.Id;
            servApp2.Residence__c=logement1.id;
            servApp2.ContactId=con.id;
            servApp2.EarliestStartTime = Date.newInstance(2020,03,01);
            servApp2.DueDate = Date.newInstance(2024,03,31);
            servApp2.Work_Order__c=lstWOs[1].id;
            servApp2.WorkTypeId = workType.Id;
            //servApp2.BundlePolicyId = '7sTSb0000000002MAA';
            servApp2.IsBundleMember = false;
            servApp2.TECH_AVP__c = null;
            servApp2.schedStartTime = DateTime.now().addDays(15);
            servApp2.SchedEndTime = DateTime.now().addDays(30);
            servApp2.Service_Contract__c = contract.Id;
            servApp2.ParentRecordId = testAcc.Id;
            servApp2.ActualStartTime = system.today();

            
            // ServiceAppointment servApp3 = TestFactory.createServiceAppointment(workorder3.Id);
            // servApp3.Category__c = 'VE Collective';
            // servApp3.Status = 'Scheduled';
            // servApp3.VE_Planning__c = false;
            // servApp3.ServiceTerritoryId = agence1.Id;
            // servApp3.EarliestStartTime = Date.newInstance(2020,03,01);
            // servApp3.DueDate = Date.newInstance(2024,03,31);
            // servApp3.Work_Order__c=lstWOs[2].id;
            // servApp3.WorkTypeId = workType.Id;
            // //servApp3.BundlePolicyId = '7sTSb0000000002MAA';
            // servApp3.IsBundleMember = false;
            // servApp3.TECH_AVP__c = true;
            // servApp3.schedStartTime = DateTime.now().addDays(15);
            // servApp3.SchedEndTime = DateTime.now().addDays(30);
            // servApp3.Service_Contract__c = contract.Id;
            // servApp3.ParentRecordId = testAcc.Id;

            lstSAs = new List<ServiceAppointment>{
                servApp1,
                servApp2
                // servApp3
            };

            insert lstSAs;

            lstServResource.add(TestFactory.createServiceResource(serviceTerrUser.id,'The service resource'));

            insert lstServResource;
            List<ServiceTerritoryMember> lstServTerrMember = new List<ServiceTerritoryMember>{
                new ServiceTerritoryMember(
                    EffectiveStartDate=Datetime.now().addYears(-1),
                    ServiceTerritoryId=agence1.Id,
                    ServiceResourceId=lstServResource[0].Id
                )
            };

            insert lstServTerrMember;

            
                AssignedResource ar = new AssignedResource(
                    ServiceAppointmentId=servApp1.id,
                    ServiceResourceId=lstServResource[0].id
                );
                AssignedResource ar2 = new AssignedResource(
                    ServiceAppointmentId=servApp2.id,
                    ServiceResourceId=lstServResource[0].id
                );
                lstAR.add(ar);
                lstAR.add(ar2);

            
            insert lstAR;
            list<AgencyAccreditation__c> lstAccr= new list<AgencyAccreditation__c>{
                
                    new AgencyAccreditation__c(
                    Agency__c=agence1.Id,
                    Name = 'test',
                    type__c='PG Installation',LocalAgency__c=agence1.Id
                ),

                new AgencyAccreditation__c(
                    Agency__c=agence1.Id,
                    Name = 'test2',
                    type__c='RGE Chaudière',LocalAgency__c=agence1.Id
                ),

                new AgencyAccreditation__c(
                    Agency__c=agence1.Id,
                    Name = 'test3',
                    type__c='RGE PAC',LocalAgency__c=agence1.Id
                ),

                new AgencyAccreditation__c(
                    Agency__c=agence1.Id,
                    Name = 'test4',
                    type__c='RGE Chauffage+',LocalAgency__c=agence1.Id
                ),
                new AgencyAccreditation__c(
                    Agency__c=agence1.Id,
                    Name = 'test5',
                    type__c='RGE Qualibois',LocalAgency__c=agence1.Id
                ),
                new AgencyAccreditation__c(
                    Agency__c=agence1.Id,
                    Name = 'test6',
                    type__c='SGS Qualicert',
                    LocalAgency__c=agence1.Id
                ),
                new AgencyAccreditation__c(
                    Agency__c=agence1.Id,
                    Name = 'test7',
                    type__c='Qualisav',
                    LocalAgency__c=agence1.Id
                ),
                new AgencyAccreditation__c(
                    Agency__c=agence1.Id,
                    Name = 'test8',
                    type__c='Ventilation+',
                    LocalAgency__c=agence1.Id
                ),
                new AgencyAccreditation__c(
                    Agency__c=agence1.Id,
                    Name = 'test9',
                    type__c='SGS Fluides',
                    LocalAgency__c=agence1.Id
                )
            };
            
            
            insert lstAccr;
            
            ContentWorkspace testWorkspace = new ContentWorkspace(Name='DocaposteXmlFile1', DeveloperName='DocaposteXmlFile1');
            insert testWorkspace;
        }

    }

    @isTest
    public static void testBatch(){
        System.runAs(mainUser){
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
            List<ServiceAppointment> lstValid2 = [SELECT Id, ServiceTerritory.Agency_Code__c, 
                                                        Account.BillingPostalCode,
                                                        ServiceTerritory.Sofactoapp_Raison_Social__r.sofactoapp__Capital_social__c,
                                                        ServiceTerritory.Sofactoapp_Raison_Social__r.sofactoapp__Forme_juridique__c, 
                                                        Account.PersonEmail,
                                                        Account.Phone,
                                                        Account.Name,
                                                        ServiceTerritory.Sofactoapp_Raison_Social__r.Name FROM ServiceAppointment
                                                        WHERE ID IN: lstSAs];
            System.debug('lstValid2:' +lstValid2);
            Test.startTest();
                BAT76_DocaposteBatch batch = new BAT76_DocaposteBatch();
                Database.executeBatch(batch);
            Test.stopTest();
        }
    }
    // @istest
    // public static void testGeneratedXML(){
    //     test.startTest();
    //         List<ServiceAppointment> lstSA= [
    //             SELECT Id,
    //    ServiceTerritory.Name,
    //    ServiceTerritory.Agency_Code__c,
    //    ServiceTerritory.Street,
    //    ServiceTerritory.Street2__c,
    //    ServiceTerritory.PostalCode,
    //    ServiceTerritory.City,
    //    ServiceTerritory.Country,
    //    ServiceTerritory.Siret__c,
    //    Account.ClientNumber__c,
    //    Account.Salutation,
    //    Account.Name,
    //    Account.BillingStreet,
    //    Account.BillingCity,
    //    Account.BillingCountry,
    //    Account.Adress_complement__c,
    //    Account.BillingPostalCode,
    //    Account.BillingAddress,
    //    Account.PersonEmail,
    //    Account.Phone,
    //    AppointmentNumber,
    //    ActualStartTime,
    //    ServiceTerritory.Sofactoapp_Raison_Social__r.Name,
    //    ServiceTerritory.Sofactoapp_Raison_Social__r.sofactoapp__Forme_juridique__c,
    //    ServiceTerritory.Sofactoapp_Raison_Social__r.sofactoapp__Capital_social__c,
    //    ServiceTerritory.Sofactoapp_Raison_Social__r.Sofacto_Adresse_Agence_2__c,
    //    ServiceTerritory.Sofactoapp_Raison_Social__r.sofactoapp__RueFactu__c,
    //    ServiceTerritory.Sofactoapp_Raison_Social__r.sofactoapp__Code_postal__c,
    //    ServiceTerritory.Sofactoapp_Raison_Social__r.sofactoapp__Ville__c,
    //    ServiceTerritory.Sofactoapp_Raison_Social__r.sofactoapp__SIREN__c,
    //    ServiceTerritory.Sofactoapp_Raison_Social__r.sofactoapp__Ville_RCS__c,
    //    Service_Contract__r.RecordType.Name,
    //    Service_Contract__r.Account.ClientNumber__c,
    //    ServiceTerritory.Sofactoapp_Raison_Social__r.sofactoapp__Rue__c,
    //    ServiceTerritoryId
    //     FROM ServiceAppointment where id in :lstSAs
    //                 ];



    //         AP93_DocaposteXMLGenerator.GenerateXML(lstSA);
    //     test.stopTest();
    // }
    @isTest
    public static void testPostalCode(){
        testAcc.BillingStreet='aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaabbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbccccccccccccccccccccccccccccccccccccccccccccc';
        update testAcc;
        System.runAs(mainUser){
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
            List<ServiceAppointment> lstValid2 = [SELECT Id, ServiceTerritory.Agency_Code__c, 
                                                        Account.BillingPostalCode,
                                                        ServiceTerritory.Sofactoapp_Raison_Social__r.sofactoapp__Capital_social__c,
                                                        ServiceTerritory.Sofactoapp_Raison_Social__r.sofactoapp__Forme_juridique__c, 
                                                        Account.PersonEmail,
                                                        Account.Phone,
                                                        Account.Name,
                                                        ServiceTerritory.Sofactoapp_Raison_Social__r.Name FROM ServiceAppointment
                                                        WHERE ID IN: lstSAs];
            System.debug('lstValid2:' +lstValid2);
            Test.startTest();
                BAT76_DocaposteBatch batch = new BAT76_DocaposteBatch();
                Database.executeBatch(batch);
            Test.stopTest();
        }
    }
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"Message": "Mocked response message", "code": "820"}');
            res.setStatusCode(200);
            return res;
        }
    }

    @isTest
    public static void testBatch2(){
        System.runAs(mainUser){
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
            lstSAs[0].ContactId = null;
            lstSAs[1].ContactId = null;
            update lstSAs;
            Test.startTest();
                BAT76_DocaposteBatch batch = new BAT76_DocaposteBatch();
                Database.executeBatch(batch);
            Test.stopTest();
        }
    }
    @isTest
    public static void testBatch3(){
        System.runAs(mainUser){
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
            logement1.Visit_Notice_Recipient__c='Owner';
            logement1.Owner__c=testAcc.id;
            update logement1;
            Test.startTest();
                BAT76_DocaposteBatch batch = new BAT76_DocaposteBatch();
                Database.executeBatch(batch);
            Test.stopTest();
        }
    }
    @isTest
    public static void testBatch4(){
        System.runAs(mainUser){
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
            logement1.Visit_Notice_Recipient__c='Legal Guardian';
            logement1.Legal_Guardian__c= testAcc.id;
            update logement1;
            // update lstSAs[1];
            Test.startTest();
                BAT76_DocaposteBatch batch = new BAT76_DocaposteBatch();
                Database.executeBatch(batch);
            Test.stopTest();
        }
    }
    @isTest
    public static void testBatch5(){
        System.runAs(mainUser){
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
            // lstSAs[1].ContactId = null;
            testAcc.Imm_Res__c='Test';
            testAcc.Floor__c='Test';
            testAcc.Door__c='1';
            update testAcc;
            logement1.Visit_Notice_Recipient__c='Administrator';
            update logement1;
            // update lstSAs[1];
            Test.startTest();
                BAT76_DocaposteBatch batch = new BAT76_DocaposteBatch();
                Database.executeBatch(batch);
            Test.stopTest();
        }
    }

    @isTest
    public static void testBatch6(){
        System.runAs(mainUser){
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
            // lstSAs[1].ContactId = null;
            Account acc= TestFactory.createAccount('TheUser');
            acc.Imm_Res__c='Test';
            acc.Floor__c='Test';
            acc.Door__c='1';
            acc.BillingCity = null;
            acc.BillingPostalCode = null;
            insert acc;
            logement1.Visit_Notice_Recipient__c='Legal Guardian';
            logement1.Legal_Guardian__c=acc.id;
            update logement1;
            // update lstSAs[1];
            Test.startTest();
                BAT76_DocaposteBatch batch = new BAT76_DocaposteBatch();
                Database.executeBatch(batch);
            Test.stopTest();
        }
    }

    @isTest
    public static void testBatch7(){
        System.runAs(mainUser){
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
            // lstSAs[1].ContactId = null;
            testAcc.Imm_Res__c='Test';
            testAcc.Floor__c='Test';
            testAcc.Door__c='1';
            testAcc.BillingCity = null;
            testAcc.BillingPostalCode = null;
            update testAcc;
            logement1.Visit_Notice_Recipient__c='Administrator';
            update logement1;
            // update lstSAs[1];
            Test.startTest();
                BAT76_DocaposteBatch batch = new BAT76_DocaposteBatch();
                Database.executeBatch(batch);
            Test.stopTest();
        }
    }

    @isTest
    public static void testBatch8(){
        System.runAs(mainUser){
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
            // lstSAs[1].ContactId = null;
            Account acc= TestFactory.createAccount('TheUser');
            acc.Imm_Res__c='Test';
            acc.Floor__c='Test';
            acc.Door__c='1';
            acc.BillingCity = null;
            acc.BillingPostalCode = null;
            insert acc;
            logement1.Visit_Notice_Recipient__c='Owner';
            logement1.Owner__c=acc.id;
            update logement1;
            // update lstSAs[1];
            Test.startTest();
                BAT76_DocaposteBatch batch = new BAT76_DocaposteBatch();
                Database.executeBatch(batch);
            Test.stopTest();
        }
    }

    @isTest
    public static void testBatch9(){
        System.runAs(mainUser){
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
            // lstSAs[1].ContactId = null;
            Account acc= TestFactory.createAccount('TheUser');
            acc.Imm_Res__c='Test';
            acc.Floor__c='Test';
            acc.Door__c='1';
            acc.BillingCity = null;
            acc.BillingPostalCode = null;
            insert acc;
            logement1.Visit_Notice_Recipient__c='Inhabitant';
            logement1.Inhabitant__c=acc.id;
            logement1.City__c = null;
            logement1.Postal_Code__c = null;
            update logement1;
            // update lstSAs[1];
            Test.startTest();
                BAT76_DocaposteBatch batch = new BAT76_DocaposteBatch();
                Database.executeBatch(batch);
            Test.stopTest();
        }
    }

    @isTest
    public static void testBatch10(){
        System.runAs(mainUser){
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
            // lstSAs[1].ContactId = null;
            Account acc= TestFactory.createAccount('TheUser');
            acc.Imm_Res__c='Test';
            acc.Floor__c='Test';
            acc.Door__c='1';
            acc.BillingCity = null;
            acc.BillingPostalCode = null;
            insert acc;
            agence1.Email__c = null;
            agence1.Phone__c = null;
            update agence1;
            agence2.Email__c = null;
            agence2.Phone__c = null;
            update agence2;
            logement1.Visit_Notice_Recipient__c='Inhabitant';
            logement1.Inhabitant__c=acc.id;
            update logement1;
            // update lstSAs[1];
            Test.startTest();
                BAT76_DocaposteBatch batch = new BAT76_DocaposteBatch();
                Database.executeBatch(batch);
            Test.stopTest();
        }
    }

    @isTest
    public static void testBatch11(){
        System.runAs(mainUser){
            Test.startTest();
                AP93_DocaposteXMLGenerator.formatNumberWithSpaces(4);
            Test.stopTest();
        }
    }

    @isTest
    public static void testBatch12(){
        System.runAs(mainUser){
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
            // lstSAs[1].ContactId = null;
            testAcc.PersonEmail = '';
            testAcc2.PersonEmail = '';
            update testAcc;
            update testAcc2;
            logement1.Visit_Notice_Recipient__c='Inhabitant';
            update logement1;

            Test.startTest();
                BAT76_DocaposteBatch batch = new BAT76_DocaposteBatch();
                Database.executeBatch(batch);
            Test.stopTest();
        }
    }
    
    @isTest
    public static void testBatch13(){
        System.runAs(mainUser){
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
            lstWOs[2].AccountId = testAcc2.Id;
            update lstWOs;
            logement1.Visit_Notice_Recipient__c='Inhabitant';
            logement1.Inhabitant__c= testAcc.id;
            update logement1;

            Test.startTest();
                BAT76_DocaposteBatch batch = new BAT76_DocaposteBatch();
                Database.executeBatch(batch);
            Test.stopTest();
        }
    }
}