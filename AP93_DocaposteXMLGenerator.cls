/**
 * @description       : 
 * @author            : JPA
 * @group             : 
 * @last modified on  : 01-30-2025
 * @last modified by  : Gavish Varma Tulsi
**/
// AP93_DocaposteXMLGenerator.GenerateXML(new List<ServiceAppointment>());
public with sharing class AP93_DocaposteXMLGenerator {
    public static String inhabitant='Inhabitant';
    public static String legalGuardian='Legal Guardian';
    public static String owner='Owner';
    public static String admin='Administrator';
    
    public static map<String, set<Id>> GenerateXML(List<ServiceAppointment> lstSA){
        
        set<Id> setFilterSAId= new set<Id>();
        set<ID> lstAgencyCode= new set<Id>();
        for(ServiceAppointment sa:lstSA){
            lstAgencyCode.add(sa.ServiceTerritoryId);
        }

        List<AgencyAccreditation__c> lstAccre= [SELECT Agency__c, 
            Eligibility__c, 
            Type__c,
            Numero_SGS__c,
            Equipement_couvert__c 
            FROM AgencyAccreditation__c 
            WHERE Agency__c = :lstAgencyCode
            AND (Eligibility__c = 'Oui propre' OR Eligibility__c = 'Oui déléguée')
        ];

        Map<Id,List<AgencyAccreditation__c>> mapAgencyIDToLstAccred= new map<Id,List<AgencyAccreditation__c>>();

        for(AgencyAccreditation__c accred:lstAccre){
            if(!mapAgencyIDToLstAccred.containsKey(accred.Agency__c)){
                mapAgencyIDToLstAccred.put(accred.Agency__c,new list<AgencyAccreditation__c>{accred});
            }else{
                List<AgencyAccreditation__c> newList=mapAgencyIDToLstAccred.get(accred.Agency__c);
                newList.add(accred);
                mapAgencyIDToLstAccred.put(accred.Agency__c, newList);
            }
        }

    
        Map<String, Docaposte_Ligne__mdt> mapDocapostMTD = Docaposte_Ligne__mdt.getAll();
        list<Docaposte_Ligne__mdt> lstDocapostMTD = new list<Docaposte_Ligne__mdt>();
        for (Docaposte_Ligne__mdt val : mapDocapostMTD.values()) {
            lstDocapostMTD.add(val);
        }

        Set<Id> relatedBundleId = new Set<Id>();
        for(ServiceAppointment sa: lstSA){
            if(sa.IsBundle && sa.BundlePolicy.Name == 'ABP - Plusieurs équipements' && sa.Subject.toLowerCase().contains('entretien')){
                relatedBundleId.add(sa.Id);
            }
        }

        Map<Id,List<ServiceAppointment>> idByServApp = new map<Id,List<ServiceAppointment>>();

        for(ServiceAppointment sa: [SELECT Id,
                                        IsBundle,
                                        RelatedBundleId,
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

        XMLStreamWriter writer = new XMLStreamWriter();

        writer.writeStartDocument(null, '1.0');
        writer.writeStartElement(null, 'Flux_Api', null);

        // Info_Flux
        writer.writeStartElement(null, 'Info_Flux', null);
        writer.writeStartElement(null, 'Version', null);
        writer.writeCharacters('V-01_' + Datetime.now().format('Hmmss'));
        writer.writeEndElement(); // Version
        writer.writeStartElement(null, 'Date_Envoi', null);
        writer.writeCharacters(String.valueOf(system.now().format('dd/MM/yyyy')));
        writer.writeEndElement(); // Date_Envoi
        writer.writeStartElement(null, 'Type_Doc', null);
        writer.writeCharacters('Avis_Passage');
        writer.writeEndElement(); // Type_Doc
        writer.writeEndElement(); // Info_Flux

        // Liste_Documents
        writer.writeStartElement(null, 'Liste_Documents', null);
        for (ServiceAppointment sa : lstSA) {
            setFilterSAId.add(sa.id);
            //! To check for phone  is not blank
            if ( String.isNotBlank(sa.ServiceTerritory?.Email__c) && String.isNotBlank(sa.ServiceTerritory?.Phone__c) ) {
                writer.writeStartElement(null, 'Document', null);

                // Commun
                writer.writeStartElement(null, 'Commun', null);
                writer.writeStartElement(null, 'Index', null);
                writer.writeCharacters(AP_Constant.truncateString(sa.id,40));
                writer.writeEndElement(); // Index
                
                // Envoi_Mail
                //Add Bundler
                if (relatedBundleId.contains(sa.Id)) {
                    List<ServiceAppointment> relatedSA = idByServApp.get(sa.Id);
                    
                    if(!relatedSA.isEmpty()){
                        ServiceAppointment firstSA = relatedSA[0];
                      
                        if (firstSA?.Service_Contract__r != null && firstSA?.Service_Contract__r?.RecordType?.DeveloperName == AP_Constant.ContratsCollectifPublic) {
                            writer.writeStartElement(null, 'Envoi_Edit', null);
                            writer.writeCharacters('OUI');
                            writer.writeEndElement(); // Envoi_Edit
                            writer.writeStartElement(null, 'Envoi_Mail', null);
                            writer.writeCharacters('NON');
                            writer.writeEndElement(); // Envoi_Mail
                        } else {
                            if (
                                (String.isNotBlank(firstSA.Residence__r?.Inhabitant__r?.PersonEmail) && firstSA.Residence__r.Visit_Notice_Recipient__c == 'Inhabitant') ||
                                (String.isNotBlank(firstSA.Residence__r?.Owner__r?.PersonEmail) && firstSA.Residence__r.Visit_Notice_Recipient__c == 'Owner') ||
                                (String.isNotBlank(firstSA.Residence__r?.Legal_Guardian__r?.PersonEmail) && firstSA.Residence__r.Visit_Notice_Recipient__c == 'Legal Guardian') ||
                                (String.isNotBlank(firstSA.Residence__r?.Account__r?.PersonEmail) && firstSA.Residence__r.Visit_Notice_Recipient__c == 'Administrator')
        
                            ) {
                                writer.writeStartElement(null, 'Envoi_Edit', null);
                                writer.writeCharacters('NON');
                                writer.writeEndElement(); // Envoi_Edit
                                writer.writeStartElement(null, 'Envoi_Mail', null);
                                writer.writeCharacters('OUI');
                                writer.writeEndElement(); // Envoi_Mail
                            } else {
                                writer.writeStartElement(null, 'Envoi_Edit', null);
                                writer.writeCharacters('OUI');
                                writer.writeEndElement(); // Envoi_Edit
                                writer.writeStartElement(null, 'Envoi_Mail', null);
                                writer.writeCharacters('NON');
                                writer.writeEndElement(); // Envoi_Mail
                            }
                        }
                    }else{
                        writer.writeStartElement(null, 'Envoi_Edit', null);
                        writer.writeCharacters('OUI');
                        writer.writeEndElement(); // Envoi_Edit
                        writer.writeStartElement(null, 'Envoi_Mail', null);
                        writer.writeCharacters('NON');
                        writer.writeEndElement(); // Envoi_Mail
                    }
                }else{
                    if (sa?.Service_Contract__r != null && sa?.Service_Contract__r?.RecordType?.DeveloperName == AP_Constant.ContratsCollectifPublic) {
                        writer.writeStartElement(null, 'Envoi_Edit', null);
                        writer.writeCharacters('OUI');
                        writer.writeEndElement(); // Envoi_Edit
                        writer.writeStartElement(null, 'Envoi_Mail', null);
                        writer.writeCharacters('NON');
                        writer.writeEndElement(); // Envoi_Mail
                    } else {
                        if (
                            (String.isNotBlank(sa.Residence__r?.Inhabitant__r?.PersonEmail) && sa.Residence__r.Visit_Notice_Recipient__c == 'Inhabitant') ||
                            (String.isNotBlank(sa.Residence__r?.Owner__r?.PersonEmail) && sa.Residence__r.Visit_Notice_Recipient__c == 'Owner') ||
                            (String.isNotBlank(sa.Residence__r?.Legal_Guardian__r?.PersonEmail) && sa.Residence__r.Visit_Notice_Recipient__c == 'Legal Guardian') ||
                            (String.isNotBlank(sa.Residence__r?.Account__r?.PersonEmail) && sa.Residence__r.Visit_Notice_Recipient__c == 'Administrator')
    
                        ) {
                            writer.writeStartElement(null, 'Envoi_Edit', null);
                            writer.writeCharacters('NON');
                            writer.writeEndElement(); // Envoi_Edit
                            writer.writeStartElement(null, 'Envoi_Mail', null);
                            writer.writeCharacters('OUI');
                            writer.writeEndElement(); // Envoi_Mail
                        } else {
                            writer.writeStartElement(null, 'Envoi_Edit', null);
                            writer.writeCharacters('OUI');
                            writer.writeEndElement(); // Envoi_Edit
                            writer.writeStartElement(null, 'Envoi_Mail', null);
                            writer.writeCharacters('NON');
                            writer.writeEndElement(); // Envoi_Mail
                        }
                    }
                }
                
                writer.writeStartElement(null, 'Attestation', null);
                writer.writeCharacters('');
                writer.writeEndElement(); // Attestation
                writer.writeStartElement(null, 'Retractation', null);
                writer.writeCharacters('');
                writer.writeEndElement(); // Retractation
                writer.writeStartElement(null, 'Signature', null);
                writer.writeCharacters('NON');
                writer.writeEndElement(); // Signature
                //RETOUR 27/06/2024
                writer.writeStartElement(null, 'Envoi_Edemat', null);
                writer.writeCharacters('NON');
                writer.writeEndElement();
                writer.writeEndElement(); // Commun

                // Info_Compl_Edit
                writer.writeStartElement(null, 'Info_Compl_Edit', null);
                writer.writeStartElement(null, 'Annexe_Log1', null);
                writer.writeCharacters('');
                writer.writeEndElement(); // Annexe_Log1
                writer.writeStartElement(null, 'Annexe_Log2', null);
                writer.writeCharacters('');
                writer.writeEndElement(); // Annexe_Log2
                writer.writeStartElement(null, 'Annexe_Log3', null);
                writer.writeCharacters('');
                writer.writeEndElement(); // Annexe_Log3
                writer.writeStartElement(null, 'Env_Retour', null);
                writer.writeCharacters('NON');
                writer.writeEndElement(); // Env_Retour
                writer.writeStartElement(null, 'Type_Affranch', null);
                writer.writeCharacters('');
                writer.writeEndElement(); // Type_Affranch
                writer.writeStartElement(null, 'Regroup', null);
                writer.writeCharacters('');
                writer.writeEndElement(); // Regroup
                writer.writeStartElement(null, 'Ordre_Doc', null);
                writer.writeCharacters('');
                writer.writeEndElement(); // Ordre_Doc
                writer.writeStartElement(null, 'Pre_Decoupe', null);
                writer.writeCharacters('');
                writer.writeEndElement(); // Pre_Decoupe
                writer.writeStartElement(null, 'Code_CGV', null);
                writer.writeCharacters('');
                writer.writeEndElement(); // Code_CGV
                writer.writeEndElement(); // Info_Compl_Edit
                
                // Avis_Passage
                writer.writeStartElement(null, 'Avis_Passage', null);
                writer.writeStartElement(null, 'Logo_Entreprise', null);
                writer.writeCharacters('Logo_IziConfort');
                writer.writeEndElement(); // Logo_Entreprise
                writer.writeStartElement(null, 'Info_Agence', null);
                writer.writeStartElement(null, 'Nom_Agence', null);
                
                writer.writeCharacters(AP_Constant.truncateString((sa.ServiceTerritory.TerritoryStat__c == 'Subsidiary'?(sa.ServiceTerritory?.Name + ' ' +sa.ServiceTerritory?.Corporate_Name__c):sa.ServiceTerritory?.Name), 40));//Service territory
                writer.writeEndElement(); // Nom_Agence
                writer.writeStartElement(null, 'Code_Agence', null);
                writer.writeCharacters(AP_Constant.truncateString((sa.ServiceTerritory?.Agency_Code__c), 6));
                writer.writeEndElement(); // Code_Agence
                writer.writeStartElement(null, 'Agence_Adr1', null);
                writer.writeCharacters(AP_Constant.truncateString((sa.ServiceTerritory?.Street), 76));
                writer.writeEndElement(); // Agence_Adr1
                writer.writeStartElement(null, 'Agence_Adr2', null);
                writer.writeCharacters(AP_Constant.truncateString((sa.ServiceTerritory?.Street2__c), 76));
                writer.writeEndElement(); // Agence_Adr2
                writer.writeStartElement(null, 'Agence_Code_Postal', null);
                writer.writeCharacters(AP_Constant.truncateString((removeExtraSpaces(sa.ServiceTerritory?.PostalCode)), 5));
                writer.writeEndElement(); // Agence_Code_Postal
                writer.writeStartElement(null, 'Agence_Ville', null);
                writer.writeCharacters(AP_Constant.truncateString((sa.ServiceTerritory?.City), 32));
                writer.writeEndElement(); // Agence_Ville
                writer.writeStartElement(null, 'Agence_Pays', null);
                writer.writeCharacters('');
                writer.writeEndElement(); // Agence_Pays
                writer.writeStartElement(null, 'Agence_Siret', null);
                writer.writeCharacters('');
                writer.writeEndElement(); // Agence_Siret
                //RETOUR 27/06/2024
                writer.writeStartElement(null, 'Mail_Agence', null);
                writer.writeCharacters(AP_Constant.truncateString(sa.ServiceTerritory?.Email__c,80));
                writer.writeEndElement(); // Mail_Agence
                //Tel_Agence
                writer.writeStartElement(null, 'Tel_Agence', null);
                writer.writeCharacters((AP_Constant.truncateString(sanitizePhoneNumber(String.valueOf(sa.ServiceTerritory?.Phone__c)),40)));
                writer.writeEndElement(); // Tel_Agence
                writer.writeEndElement(); // Info_Agence
                // INFO DES INHABITANT
                //Add Bundler
                if(relatedBundleId.contains(sa.Id)){
                    List<ServiceAppointment> relatedSA = idByServApp.get(sa.Id);
                    if(!relatedSA.isEmpty()){
                        ServiceAppointment firstSA = relatedSA[0];
                        writer.writeStartElement(null, 'Info_Client', null);
                        writer.writeStartElement(null, 'Num_Client', null);
                        writer.writeCharacters(AP_Constant.truncateString((firstSA?.Account?.ClientNumber__c), 40));
                        writer.writeEndElement(); // Num_Client
                    }else{
                        writer.writeStartElement(null, 'Info_Client', null);
                        writer.writeStartElement(null, 'Num_Client', null);
                        writer.writeCharacters(AP_Constant.truncateString((null), 40));
                        writer.writeEndElement(); // Num_Client
                    }
                }else{
                    writer.writeStartElement(null, 'Info_Client', null);
                    writer.writeStartElement(null, 'Num_Client', null);
                    writer.writeCharacters(AP_Constant.truncateString((sa?.Account?.ClientNumber__c), 40));
                    writer.writeEndElement(); // Num_Client
                }

                //Build the prefix of address
                if (sa.Residence__r.Visit_Notice_Recipient__c == owner){
                    buildResidanceType(writer,sa.Contact,sa.Residence__r?.Owner__r,owner,sa.Residence__r);
                }else if(sa.Residence__r.Visit_Notice_Recipient__c == legalGuardian){
                    buildResidanceType(writer,sa.Contact,sa.Residence__r?.Legal_Guardian__r,legalGuardian,sa.Residence__r);
                }else if(sa.Residence__r.Visit_Notice_Recipient__c == admin){
                    buildResidanceType(writer,sa.Contact,sa.Residence__r?.Account__r,admin,sa.Residence__r);
                }else {
                    //RETOUR DE FLP-> CATER FOR NULL VALUE AND TYPE INHABITANT
                    buildResidanceType(writer,sa.Contact,sa.Residence__r?.Inhabitant__r,inhabitant,sa.Residence__r);
                }

                //!To check
                writer.writeStartElement(null, 'Pays_Client', null);
                writer.writeCharacters('');
                writer.writeEndElement(); // Pays_Client
                writer.writeStartElement(null, 'Code_Payeur', null);

                //Add Bundler
                if(relatedBundleId.contains(sa.Id)){
                    List<ServiceAppointment> relatedSA = idByServApp.get(sa.Id);
                    
                    if(!relatedSA.isEmpty()){
                        ServiceAppointment firstSA = relatedSA[0];
                        writer.writeCharacters(AP_Constant.truncateString((firstSA.Service_Contract__r?.Account?.ClientNumber__c), null));
                        writer.writeEndElement(); // Code_Payeur
                        writer.writeEndElement(); // Info_Client
                    }else{
                        writer.writeCharacters(AP_Constant.truncateString((null), null));
                        writer.writeEndElement(); // Code_Payeur
                        writer.writeEndElement(); // Info_Client
                    }
                }else{
                    writer.writeCharacters(AP_Constant.truncateString((sa.Service_Contract__r?.Account?.ClientNumber__c), null));
                    writer.writeEndElement(); // Code_Payeur
                    writer.writeEndElement(); // Info_Client
                }

                writer.writeStartElement(null, 'Info_Rdv', null);
                writer.writeStartElement(null, 'Num_Rdv', null);
                writer.writeCharacters(AP_Constant.truncateString(sa?.AppointmentNumber== null ? '' :sa?.AppointmentNumber,11));
                writer.writeEndElement(); // Num_Rdv
                writer.writeStartElement(null, 'Date_Rdv', null);
                writer.writeCharacters(AP_Constant.truncateString(sa.SchedStartTime.format('dd/MM/yyyy'),10));
                writer.writeEndElement(); // Date_Rdv
                writer.writeStartElement(null, 'Periode_Rdv', null);
                writer.writeCharacters(sa?.ArrivalWindowEndTime?.hour() >=8  && sa?.ArrivalWindowEndTime?.hour() < 13 ? 'LE MATIN':'APRES MIDI');
                writer.writeEndElement(); // Periode_Rdv
                writer.writeStartElement(null, 'Image_Rdv', null);
                writer.writeCharacters('Image_rdv2.jpg');
                writer.writeEndElement(); // Image_Rdv
                writer.writeStartElement(null, 'Tel_Rdv', null);
                writer.writeCharacters(AP_Constant.truncateString(sanitizePhoneNumber(String.valueOf(sa.ServiceTerritory?.Phone__c)),14 ));
                writer.writeEndElement(); // Tel_Rdv
                writer.writeStartElement(null, 'Mail_Rdv', null);
                writer.writeCharacters(AP_Constant.truncateString(sa.ServiceTerritory?.Email__c,38));
                writer.writeEndElement(); // Mail_Rdv
                writer.writeEndElement(); // Info_Rdv

                // Info_Commerciale
                writer.writeStartElement(null, 'Info_Commerciale', null);
                if (lstDocapostMTD.isEmpty()) {
                    writer.writeStartElement(null, 'Ligne1', null);
                    writer.writeCharacters('');
                    writer.writeEndElement(); // Ligne1
                    writer.writeStartElement(null, 'Ligne2', null);
                    writer.writeCharacters('');
                    writer.writeEndElement(); // Ligne2
                    writer.writeStartElement(null, 'Ligne3', null);
                    writer.writeCharacters('');
                    writer.writeEndElement(); // Ligne3
                    writer.writeStartElement(null, 'Ligne4', null);
                    writer.writeCharacters('');
                    writer.writeEndElement(); // Ligne4
                } else {
                    writer.writeStartElement(null, 'Ligne1', null);
                    writer.writeCharacters(String.isBlank(lstDocapostMTD[0].Ligne1__c)==true?'':lstDocapostMTD[0]?.Ligne1__c);
                    writer.writeEndElement(); // Ligne1
                    writer.writeStartElement(null, 'Ligne2', null);
                    writer.writeCharacters(String.isBlank(lstDocapostMTD[0].Ligne2__c)==true?'':lstDocapostMTD[0]?.Ligne2__c);
                    writer.writeEndElement(); // Ligne2
                    writer.writeStartElement(null, 'Ligne3', null);
                    writer.writeCharacters(String.isBlank(lstDocapostMTD[0].Ligne3__c)==true?'':lstDocapostMTD[0]?.Ligne3__c);
                    writer.writeEndElement(); // Ligne3
                    writer.writeStartElement(null, 'Ligne4', null);
                    writer.writeCharacters(String.isBlank(lstDocapostMTD[0]?.Ligne4__c)==true?'':lstDocapostMTD[0]?.Ligne4__c);
                    writer.writeEndElement(); // Ligne4
                }
                writer.writeEndElement(); // Info_Commerciale

                
                // Info_Juridique
                writer.writeStartElement(null, 'Info_Juridique', null);
                writer.writeStartElement(null, 'Siege_Raison_Sociale', null);
                writer.writeCharacters(AP_Constant.truncateString((sa.ServiceTerritory?.Sofactoapp_Raison_Social__r?.sofactoapp_Agence__r?.Corporate_Name__c), 80));
                writer.writeEndElement(); // Siege_Raison_Sociale
                writer.writeStartElement(null, 'Forme_Juridique', null);
                writer.writeCharacters(AP_Constant.truncateString((sa.ServiceTerritory?.Sofactoapp_Raison_Social__r?.sofactoapp_Agence__r?.Legal_Form__c), 255));
                writer.writeEndElement(); // Forme_Juridique
                writer.writeStartElement(null, 'Capital_Social', null);
                writer.writeCharacters(String.valueOf(sa.ServiceTerritory.Sofactoapp_Raison_Social__r?.sofactoapp_Agence__r?.Capital_in_Eur__c==null?'' :formatNumberWithSpaces(sa.ServiceTerritory?.Sofactoapp_Raison_Social__r?.sofactoapp_Agence__r?.Capital_in_Eur__c)));
                writer.writeEndElement(); // Capital_Social

                String RaisonSocialAdd = AP_Constant.truncateString(sa?.ServiceTerritory?.Sofactoapp_Raison_Social__r?.sofactoapp_Agence__r?.Corporate_Street__c , 255);
                String RaisonSocialAdd2 = AP_Constant.truncateString(sa?.ServiceTerritory?.Sofactoapp_Raison_Social__r?.sofactoapp_Agence__r?.Corporate_Street2__c , 255);
                writer.writeStartElement(null, 'Siege_Adresse_L1', null);
                writer.writeCharacters(RaisonSocialAdd);
                writer.writeEndElement(); // Siege_Adresse_L1
                writer.writeStartElement(null, 'Siege_Adresse_L2', null);
                writer.writeCharacters(RaisonSocialAdd2);
                writer.writeEndElement(); // Siege_Adresse_L2
                writer.writeStartElement(null, 'Siege_Code_Postal', null);
                writer.writeCharacters(AP_Constant.truncateString((removeExtraSpaces(sa.ServiceTerritory?.Sofactoapp_Raison_Social__r?.sofactoapp_Agence__r?.Corporate_ZipCode__c)), 6));
                writer.writeEndElement(); // Siege_Code_Postal
                writer.writeStartElement(null, 'Siege_Ville', null);
                writer.writeCharacters(AP_Constant.truncateString((sa.ServiceTerritory?.Sofactoapp_Raison_Social__r?.sofactoapp_Agence__r?.Corporate_City__c), 40));
                writer.writeEndElement(); // Siege_Ville
                writer.writeStartElement(null, 'Siege_Siren', null);
                writer.writeCharacters(AP_Constant.truncateString((sa?.ServiceTerritory?.Sofactoapp_Raison_Social__r?.sofactoapp_Agence__r?.Siren__c), 11));
                writer.writeEndElement(); // Siege_Siren
                writer.writeStartElement(null, 'Ville_RCS', null);
                writer.writeCharacters(AP_Constant.truncateString((sa.ServiceTerritory?.Sofactoapp_Raison_Social__r?.sofactoapp_Agence__r?.RCS__c), 40));
                writer.writeEndElement(); // Ville_RCS
                writer.writeEndElement(); // Info_Juridique
                writer.writeStartElement(null, 'Nom_Site_Internet', null);
                writer.writeCharacters('www.iziconfort.com');
                writer.writeEndElement();
                // Logos_Certifiants
                writer.writeStartElement(null, 'Logos_Certifiants', null);
                List<AgencyAccreditation__c> lstSpecificAccred = new list<AgencyAccreditation__c>();
                if(mapAgencyIDToLstAccred.containsKey(sa.ServiceTerritoryId)){
                    lstSpecificAccred = mapAgencyIDToLstAccred.get(sa.ServiceTerritoryId);
                }
                if(lstSpecificAccred!=null){
                    for (Integer i = 0; i < lstSpecificAccred.size(); i++) {
                        String logo=getLogo(lstSpecificAccred[i]);
                        if(logo!=''){
                            writer.writeStartElement(null, 'Logo', null);
                            writer.writeStartElement(null, 'Logo_Certifiant', null);
                            writer.writeCharacters(logo);
                            writer.writeEndElement(); // Logo_Certifiant
                            writer.writeStartElement(null, 'num_Habilitation', null);
                            writer.writeCharacters('');
                            
                            // writer.writeCharacters(lstSpecificAccred[i]?.Numero_SGS__c != null ? lstSpecificAccred[i]?.Numero_SGS__c : '');
                            writer.writeEndElement(); // num_Habilitation
                            writer.writeEndElement(); // Logo
                        }
                        
                    }
                }
                writer.writeEndElement(); // Logos_Certifiants
                writer.writeEndElement(); // Avis_Passage

                writer.writeEndElement(); // Document
            }
        }

        writer.writeEndElement(); // Liste_Documents
        writer.writeEndElement(); // Flux_Api
        writer.writeEndDocument();

        String xmlString = writer.getXmlString();
        map<String, set<Id>> returnMap =  new map<String, set<Id>>{
            xmlstring => setFilterSAId
        };
    
        return returnMap;
        
    }


   

    @InvocableMethod(label='Batch Docaposte' description='Call batch for docaposte(Avis De Passage)')
    public static void batchDocaposte() {
        BAT76_DocaposteBatch batch = new BAT76_DocaposteBatch();
        Database.executeBatch(batch, 200);
    }
    public static string getLogo(AgencyAccreditation__c a){
        if(a.Type__c =='PG Installation') {
            return 'logo_certif1';//log_PGI
        }else if(a.Type__c == 'RGE Chaudière'){
            return 'logo_certif6';// logoqualibatRGE
        }
        else if(a.Type__c == 'RGE PAC'){
            return 'logo_certif5';// logo_REG_QualiPAC
        }
        //MRA 13-04-2022 IMN-764 : START
        else if(a.Type__c == 'RGE Chauffage+'){
            return 'logo_certif2';// LogoChauffagePlus
        }
        else if(a.Type__c == 'RGE Qualibois'){
            return 'logo_certif4';// logo_REG_QualiBois
        }
        //MRA 13-04-2022 IMN-764 : END
        else if(a.Type__c =='SGS Qualicert'){
            return 'logo_certif3';// LogoQualicert
        }else if(a.Type__c == 'Qualisav'){
            return 'logo_certif8';// Qaulisav_RVB
        }
        else if(a.Type__c == 'Ventilation+'){
            return 'logo_certif7';// LogoVentilation
        }else{
            return '';
        }
    }
    public static String buildPrefix(String etage,String floor,String door ){
            String prefixAdd='';
            if(String.isNotBlank(etage)){
                prefixAdd+=' Bat '+etage;
            }
            if(String.isNotBlank(floor)){
                prefixAdd+=' Etage '+floor;
            }
            if(String.isNotBlank(door)){
                prefixAdd+=' Porte '+door;
            }
            return prefixAdd;
    }
    public static void buildResidanceType(XMLStreamWriter writer ,Contact con, Account acc,String type,Logement__c residence){
        if(acc?.RecordType?.DeveloperName==AP_Constant.businessAcc){
            writer.writeStartElement(null, 'Civilite_Client', null);
            writer.writeCharacters(AP_Constant.truncateString(modifySalutation(con?.Salutation), 4));
            writer.writeEndElement(); // Civilite_Client
            writer.writeStartElement(null, 'Nom_Client', null);
            writer.writeCharacters(AP_Constant.truncateString(santizeString(con?.Name), 33));
            writer.writeEndElement(); // Nom_Client
        }else{
            writer.writeStartElement(null, 'Civilite_Client', null);
            writer.writeCharacters(AP_Constant.truncateString(modifySalutation(acc?.Salutation), 4));
            writer.writeEndElement(); // Civilite_Client
            
            writer.writeStartElement(null, 'Nom_Client', null);
            String fullName=santizeString(((String.isBlank(acc?.LastName)?'':acc?.LastName)+ ' '+(String.isBlank(acc?.FirstName)?'':acc?.FirstName)));
            writer.writeCharacters(AP_Constant.truncateString(fullName, 33));
            writer.writeEndElement(); // Nom_Client
        }
        if(type==admin||type==legalGuardian ||type==owner){
            String prefixAdd=buildPrefix(acc?.Imm_Res__c,acc?.Floor__c,acc?.Door__c); 
            BuildAddress(writer ,prefixAdd,acc?.BillingStreet,acc?.Adress_Complement__c);
            writer.writeStartElement(null, 'CP_Client', null);
            writer.writeCharacters(AP_Constant.truncateString((removeExtraSpaces(acc?.BillingPostalCode)), 5));
            writer.writeEndElement(); // CP_Client
            writer.writeStartElement(null, 'Ville_Client', null);
            writer.writeCharacters(AP_Constant.truncateString((acc?.BillingCity), 32));
            writer.writeEndElement(); // Ville_Client
        }else{
            //FOR INHABITANT AND Visit_Notice_Recipient == NULL
            String prefixAdd=buildPrefix(residence?.Imm_Res__c,residence?.Floor__c,residence?.Door__c); 
            BuildAddress(writer ,prefixAdd,residence?.Street__c,residence?.Adress_Complement__c);
            writer.writeStartElement(null, 'CP_Client', null);
            writer.writeCharacters(AP_Constant.truncateString((removeExtraSpaces(residence?.Postal_Code__c)), 5));
            writer.writeEndElement(); // CP_Client
            writer.writeStartElement(null, 'Ville_Client', null);
            writer.writeCharacters(AP_Constant.truncateString((residence?.City__c), 32));
            writer.writeEndElement(); // Ville_Client
        }
        
        writer.writeStartElement(null, 'Email_Client', null);
        writer.writeCharacters(AP_Constant.truncateString(String.isBlank(acc?.PersonEmail)?'':acc?.PersonEmail,80));
        writer.writeEndElement(); // Nom_Agence
        writer.writeStartElement(null, 'Num_Tel_Portable_Client', null);
        writer.writeCharacters((AP_Constant.truncateString(acc?.PersonMobilePhone==null?'':sanitizePhoneNumber(String.valueOf(acc?.PersonMobilePhone)),10)));
        writer.writeEndElement(); // Nom_Agence
    }
 
    public static List<String> SeperateTheAddress(String street){
        List<String> batches = new List<String>();
        Integer batchSize = 38;
        street=santizeString(street);
        List<String> TheAddress= new list<String>();
        theAddress= street.split(' +');
        integer counter=0;
        String str='';
        String val='';
        for(integer i =0; i<theAddress.size();i++){
        
            if(counter==4){
                break;
            }
            if(val!=''){
                val+= ' '+theAddress[i];
            }else{
                val=theAddress[i];
            }
            if(val.length()<=batchSize){
                str= val;
                if(i==theAddress.size()-1){
                    batches.add(str);
                }
                
            }else{

                batches.add(str);
                str='';
                val='';//SET VALUE TO NULL VAL;
                i--;
                counter++;
            }

        }
        return batches;
    }
    public static String removeExtraSpaces(String input) {
        if (input == null) {
            return null;
        }
        // Trim the input to remove leading and trailing spaces
        String trimmedInput = input.trim();
        
        // Use regular expression to remove all spaces
        String result = trimmedInput.replaceAll(' ', '');

        return result;
    }
    public static String formatNumberWithSpaces(Decimal num) {
        String fullValue = String.valueOf(num);
        // List<String> splittedValue= fullValue.split('.');
        String numStr= fullValue.substringBefore('.');
        String dec= fullValue.substringAfter('.');
        String formattedNumber ='';
        Integer counter = 0;
        // Iterate over the string from the end to the beginning
        for (Integer i = numStr.length() ; i >= 1; i--) {
            formattedNumber+= numStr.substring(i-1,i);
            counter++;
            // Add a space after every third character
            if (Math.mod(counter, 3) == 0 && i != 0) {
                formattedNumber+=' ';
                counter=0;
                // formattedNumber.append(' ');
            }
        }
        // Reverse the string as we constructed it backwards and add the decimal part to it
        String finalString= formattedNumber.reverse().toString()+','+dec;
        return finalString;
    }
    private static String modifySalutation(String salutation){
        
        if(String.isNotBlank(salutation)){
            Pattern emailPattern = Pattern.compile('^[a-zA-Z0-9]+$');
            Matcher emailMatcher = emailPattern.matcher(salutation);
            Boolean isValidEmail = emailMatcher.matches();
            if(salutation.toLowerCase().contains('monsieur')){
                return 'Mr.';
            }else if(salutation.toLowerCase().contains('madame')){
                return 'Mme';
            }else if(salutation.trim().length()==1&&(!emailMatcher.matches())){
                return '';
            }
            return salutation;
        }
        
        return '';
    }
    private static void BuildAddress(XMLStreamWriter writer ,String prefixAdd,String street, String complement){
        
        List<String> lstCombineAllAddress= new list<String>();

        if(String.isNotBlank(prefixAdd)){
            List<String> lstPrefix=SeperateTheAddress(prefixAdd);

            for(String str:lstPrefix){
                lstCombineAllAddress.add(str);
            }
        }

        if(String.isNotBlank(street)){
            List<String> lstAddress=SeperateTheAddress(street);

            for(String str:lstAddress){
                lstCombineAllAddress.add(str);
            }
        }

        if(String.isNotBlank(complement)){
            List<String> lstAddComplement=SeperateTheAddress(complement);

            for(String str:lstAddComplement){
                lstCombineAllAddress.add(str);
            }
        }
        Integer sizeLst= lstCombineAllAddress.size();
        if(sizeLst>0){
            if(sizeLst<4){
                Integer counter=0;
                for(Integer i=0;i<sizeLst;i++){
                    writer.writeStartElement(null, 'Adresse_Client_L' + (i + 1), null);
                    writer.writeCharacters(lstCombineAllAddress[i]);
                    writer.writeEndElement(); 
                    counter++;
                }

                for(Integer i=sizeLst;i<4;i++){
                    writer.writeStartElement(null, 'Adresse_Client_L' + (i + 1), null);
                    writer.writeCharacters('');
                    writer.writeEndElement(); 
                }
            }else if (sizeLst==4){
                for(Integer i=0;i<sizeLst;i++){
                    writer.writeStartElement(null, 'Adresse_Client_L' + (i + 1), null);
                    writer.writeCharacters(lstCombineAllAddress[i]);
                    writer.writeEndElement(); 
                }
            }else{
                for(Integer i=0;i<4;i++){
                    writer.writeStartElement(null, 'Adresse_Client_L' + (i + 1), null);
                    writer.writeCharacters(lstCombineAllAddress[i]);
                    writer.writeEndElement(); 
                }
            }
        }
    }
    public static  string santizeString(String s){
        string input = s.replaceAll('[^a-zA-Z0-9-\\s\\p{L}+]', ' ');

        return AP_Constant.convertFrenchToEnglish(input);
    }
    public static String sanitizePhoneNumber(String phoneNumber) {
        if (String.isBlank(phoneNumber) ) {
            return null;
        }
        // Replace all periods with an empty string
        phoneNumber = phoneNumber.replace('.', '');
        return phoneNumber;
    }
}