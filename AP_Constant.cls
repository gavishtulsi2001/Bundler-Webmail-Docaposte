/**
 * @File Name          : AP_Constant.cls
 * @Description        :
 * @Author             : RRJ
 * @Group              :
 * @Last Modified By   : Gavish Varma Tulsi
 * @Last Modified On   : 01-30-2025
 * @Modification Log   :
 *==============================================================================
 * Ver         Date                     Author                    Modification
 *==============================================================================
 * 1.0    20/06/2019, 10:50:14   RRJ     Initial Version
 * 1.1    01/08/2019, 16:50:14   ARA     added picklist values for equipment type for work type
 * 1.2    07/10/2019, 15:26:37   ANA     added picklist values for Service Appointment Status
 **/
public with sharing class AP_Constant {
	//get recordTypeId
	public static Id getRecordTypeId(String objectType, String recordTypeLabel) {
		System.Debug('### getContactRecordType' + UserInfo.getUserName());
		SObject obj;

		// Describing Schema
		Schema.SObjectType res = Schema.getGlobalDescribe().get(ObjectType);

		if (res != null) {
			obj = res.newSObject();

			// Describing Object
			Schema.DescribeSObjectResult desRes = obj.getSObjectType().getDescribe();
			if (desRes != null) {
				Map<string, schema.recordtypeinfo> recordTypeMap = desRes.getRecordTypeInfosByName();

				if (recordTypeMap != null) {
					Schema.RecordTypeInfo recordTypeRes = recordTypeMap.get(recordTypeLabel);

					if (recordTypeRes != null) {
						return recordTypeRes.getRecordTypeId();
					}
				}
			}
		}

		return null;
	}
	
	public static String removeHTMLTags(String input) {
		input = input.replaceAll('&#39;', '\'');
        String htmlPattern = '<[^>]+>';
        return input.replaceAll(htmlPattern, '');
    }
	public static Id getRecTypeId(String objName, String recTypeDevName) {
		return Schema.getGlobalDescribe().get(objName).getDescribe().getRecordTypeInfosByDeveloperName().get(recTypeDevName).getRecordTypeId();
	}

    //14-11-2022 : ARM : get user timezone difference 
	public static Integer getUserTimezoneDiff() {
		Datetime systemDateTime = System.now();
		TimeZone tz = UserInfo.getTimeZone();

        return (tz.getOffset(systemDateTime)) / 3600000;
	}

	//RRJ 20190730
	public class CustomException extends Exception {
	}

	//ARM 04/04/2023 : PHE-508
	public static String sanitiseString(String s){
		return String.isBlank(s)?'':s.replaceAll('[^a-zA-Z0-9-\\s+]', '');
	}
	//ARM 03/01/2024 : PHE- 1345
	public static String removeNewLinesRegex(String inputString) {
        if (String.isNotBlank(inputString)) {
            return inputString.replaceAll('\\r\\n+', ' ');
        }
        return inputString;
    }

	//PHE-1545 SBL 01/07/24
	public static Map<String,String> getValidEquipmentPrime(){
		
		Map<String, String> mapValidEquipment = new Map<String, String>();		
		//Produit.Equipment_type__c >> Asset.RecordType.DeveloperName
		mapValidEquipment.put('ChaufferieGaz', '');
		mapValidEquipment.put('ChaufferieFioul', '');
		mapValidEquipment.put('Chaudièregaz', '');
		mapValidEquipment.put('Radiateurgaz','');
		mapValidEquipment.put('Aerotherme,Radiant','');
		mapValidEquipment.put('Chaudièrefioul','');
		mapValidEquipment.put('Poêleàgranulés','');
		mapValidEquipment.put('PompeàchaleurhybrideFioul','');
		mapValidEquipment.put('PompeàchaleurhybrideGaz','');
		mapValidEquipment.put('Chauffe-eaugaz','');

		return mapValidEquipment;
	}

	public static String leadVisitStatusDoneOk = 'Done and OK';
	public static String leadVisitStatusDoneFailed = 'Done and failed';
	public static String leadVisitStatusNeedToBePlanned = 'Need to be replanned';

	public static String leadLeadSourceBlue = 'Site BLUE';

	public static String ws_Authorization = 'Authorization';
	public static String ws_ContentType = 'Content-Type';
	public static String ws_XAuthToken = 'X-Auth-Token';
	public static String ws_CacheControl = 'Cache-Control';
	public static String ws_Accept = 'Accept';
	public static String ws_AcceptValue = '*/*';
	public static String ws_Username = 'username';
	public static String ws_Password = 'password';
	public static String ws_Token = 'token';

	//Webservice Constants
	public static String ws_Error = 'Error';
	public static String ws_Status = 'Status';
	public static String ws_Message = 'Message';
	public static String ws_URL = 'URL';

	public static String ws_Blue_State = 'state';

	//Lead
	public static String leadStatusNew = 'New';

	//ANA START  Case Type picklist values

	public static String caseTypeInstallation = 'Installation';
	public static String caseTypeMaintenance = 'Maintenance';

	//CASE ORIGIN

	public static String caseOriginChamDigital = 'Cham Digital';

	//Case Stats
	public static String caseStatusAttenteCham = 'En attente de Cham';
	public static String caseStatusInProgress = 'In Progress';
	
	//Case  TYPE for anomalie
	public static string caseTypeA1Eqp = 'A1 Equipement';
	public static string caseTypeA2Eqp = 'A2 Equipement';
	public static string caseTypeA1Log = 'A1 - Logement';
	public static string caseTypeA2Log = 'A2 - Logement';
	public static string caseTypeDGIEqp = 'DGI Equipement';
	public static string caseTypeDGILog = 'DGI - Logement';

	//Case anomalie 
	public static string caseAnomalieOuverte = 'Ouverte';
	public static string caseAnomalieCoursTraitement = 'En cours de traitement';
	public static string caseAnomalieRefusClient = 'Refus client';
	public static string caseAnomalieResolue = 'Résolue';
	public static string caseAnomalieNonResolue = 'Non résolue';
	public static string caseAnomalieNonResolueResilie = 'Non résolue et résiliée';

	//Case courier
	public static string caseCourierAEnvoyerAuClient = 'A envoyer au client';
	public static string caseCourierEnvoyeAuClient = 'Envoyé au client';
	public static string caseCourier1ereRelance = '	1ère relance';
	public static string caseCourierCourrierResiliation = 'Courrier résiliation';

	//picklist Values Object: ServiceAppointment, Field: Category__c
	public static String ServAppCategoryMisEnServ = 'Mise en service';
	public static String ServAppCategoryVisiteEntr = 'Visite d_entretien';
	public static String ServAppCategoryRemDappa = 'Remplacement dappareil';
	public static String ServAppCategoryDepannage = 'Depannage';
	public static String ServAppCategoryVisiteConf = 'Premiere_visite';
	public static String ServAppCategoryRamonage = 'Ramonage';
	public static String ServAppCategoryControle = 'Controle';
	public static String ServAppCategoryDivers = 'Divers';
	public static String ServAppCategoryDevis = 'Devis';
	public static String ServAppCategoryPose = 'Pose';
	public static String ServAppCategoryVisiteForfaitaire = 'Visite forfaitaire';
	public static String ServAppCategoryVisiteTec = 'Visite technique';
	public static String ServAppCategoryVEInd = 'VE Individuelle';

	//Mapping ServiceAppointment.Category__c code
	public static String ServAppCategoryMES = 'MES';
	public static String ServAppCategoryVEN = 'VEN';
	public static String ServAppCategoryREM = 'REM';
	public static String ServAppCategoryDEP = 'DEP';
	public static String ServAppCategoryVIC = 'VIC';
	public static String ServAppCategoryRAM = 'RAM';
	public static String ServAppCategoryCTL = 'CTL';
	public static String ServAppCategoryDIV = 'DIV';
	public static String ServAppCategoryDEV = 'DEV';
	public static String ServAppCategoryVFO = 'VFO';
	public static String ServAppCategoryVIT = 'VIT';

	//These variables are used in AP05_WSCalculateTVA
	public static string qu1_autr = 'Autres';
	public static string qu1_plus2ans = 'Particulier logement de PLUS de 2 ans';
	public static string qu1_moins2ans = 'Particulier logement moins de 2 ans';
	public static string qu2_oui = 'Oui';
	public static string qu2_non = 'Non';
	public static string qu2_jenesaispas = 'Je ne sais pas';
	public static string errorMsg = 'Merci de bien vouloir sélectionner votre profil et indiquer si votre équipement est un équipement à Haute Performance Énergétique pour passer à l\'étape suivante';

	//ServiceAppointment values
	public static string servAppStatusNone = 'None';
	public static string servAppStatusPlanned = 'Planned';
	public static String servAppCatVisitEntretien = 'Visite d_entretien';
	public static String servAppStatusCancelled = 'Cancelled';
	public static String servAppStatCatCancelled = 'Cancelled';
	public static String servAppStatCatCompleted = 'Completed';
	public static String servAppStatusScheduled = 'Scheduled';

	//ANA 07/10/2019 Service Appointment Status Picklist values START
	public static String servAppStatusImpoToFinish = 'Impossible to finish';
	public static String servAppStatusEfectueConc = 'Done OK';
	public static String servAppStatusTravauxAprevoir = 'Client works to be planned';
	public static String servAppStatusClientAbsent = 'Done client absent';
	public static String servAppStatusChaudiereGaz = 'Premier entretien Chaudière gaz';
	public static String servAppStatusImposFinish = 'Impossible to finish';
	public static String servAppStatusWorkPlan = 'Client works to be planned';

	//SBH 22/10/2019 Added picklist values
	public static String servAppStatusInProgress = 'In Progress';
	public static String servAppStatusEnAttenteClient = 'En attente appel client';
	public static String servAppStatusDispatched = 'Dispatched';
	public static String servAppStatusOnHold = 'On Hold';

	//ANA  07/10/2019 Service Appointment Status Picklist values END
	//SBH: Added status for AP27
	//work order values
	public static String wrkOrderStatusNouveau = 'New';
	public static String wrkOrderPriorityNormal = 'Normale';
	public static String wrkOrderStatusInProgress = 'In Progress';

	//work type values
	public static String wrkTypeTypeMaintenance = 'Maintenance';
	// START ARA added picklist values for Equipment_type__c on Object work type
	public static String wrkTypeEquipmentTypeChaudieregaz = 'Chaudière gaz';
	public static String wrkTypeEquipmentTypeChaudierefioul = 'Chaudière fioul';
	public static String wrkTypeEquipmentTypePompeachaleur = 'Pompe à chaleur hybride Fioul';

	//asset values
	public static String assetStatusActif = 'Actif';
	public static String equipTypeChaudiereGaz = 'Chaudière gaz';
	public static String equipTypePompechaleurAirEau = 'Pompe à chaleur air/eau';

	//account values
	public static String accSourceSiteMyChauffage = 'Site MyChauffage';
	public static String accStatusEnAttenteVisit = 'En attente de visite';

	//Account recordtype
	public static string businessAcc='BusinessAccount';

	//RRJ 20190802 AP_constant FROM PROD

	//Lead RecordType
	public static String leadRTPisteBlue = 'Pistes_BLUE';

	public static String serviceAppointmentStatusDoneOK = 'Done OK';
	public static String serviceAppointmentStatusDoneKO = 'Done KO';

	//Opportunity Variable
	public static String oppStageQua = 'Qualification';
	public static String oppStageProposal = 'Proposal';
	public static String oppStageDevisValideEnAttenteInter = 'Devis validé - en attente d\'intervention';
	public static String oppStageClosedWon = 'Closed Won';
	public static String oppStageClosedLost = 'Closed Lost';
	public static String oppStageExpired = 'Expired';
	public static String oppStageNegotiation = 'Negotiation';
	public static String oppStageOpen = 'Open';

	//Account picklist Values:
	public static String accAccountSourceSiteBlue = 'Site BLUE';

	//Status values
	public static String StatusClosed = 'Closed';
	public static String ServiceResourceLevelJunior = 'Junior';

	//RRJ 20190802 END

	//ANA START 20191015 Shipment Status
	public static String ShipStatusLivre = 'Livré';
	public static String ShipSatisfactionElevee = 'Elevee';
	public static String ShipSatisfactionMoyenne = 'Moyenne';
	public static String ShipSatisfactionFaible = 'Faible';

	//Shipment record type
	public static String RTReceptionFournisseur = 'Reception Fournisseur';

	//ANA 20191015 END

	//LocationType variables
	public static String virtuallocation = 'Virtual';

	//Order variables
	public static String OrdStatusAchat = 'Demande d\'achats';
	public static String OrdStatusAchatApprove = 'Demande_d\'achats_approuvée';
	public static String OrdStatusAccuseReceptionInterne = 'Accusé de réception interne';
	public static String ordStatusCommandeEmise = 'Accusé de réception fournisseurs';
	public static String OrdStatusAccuseReception = 'Accusé de Réception';
	public static String ordStatusEnCoursLivraison = 'En_cours_de_livraison';
	public static String OrdStatusSolde = 'Soldée';
	public static String ordStatusReceptPartiellement = 'Receptionne partiellement';
	public static String ordStatusAnnule = 'Annulé';
	public static String ordRtCommandeFournisseur = 'Commandes_fournisseurs';

	//Order rt names
	public static String orderRtCommandeFournisseur = 'Commandes_fournisseurs';

	//quote variables
	public static String quoteStatusValideSigne = 'Validé, signé - en attente d\'intervention';
	public static String quoteStatusDraft = 'Draft';
	public static String quoteStatusInReview = 'In Review';
	public static String quoteStatusValideSigneTermine = 'Validé, signé et terminé';
	public static String quoteStatusValideSigneAbandonne = 'Validé,signé mais abandonné';
	public static String quoteStatusExpired = 'Expired';
	public static String quoteStatusDenied = 'Denied';
	public static String quoteStatusNeedsReview = 'Needs Review';

	//product request variables :
	public static String productRequestStatusBrouillon = 'Brouillon';
	public static String productRquestTypeDemandeAchat = 'demande_achats';

	//product request line item variables:
	public static String prliStatusEnCourDeDemande = 'En cours de commande';
	public static String prliReserveAPreparer = 'Réservé à préparer';
	public static String prliStatusACommander = 'A commander';

	// product variables
	public static String productFamilleArticleAccessoir = 'Accessoires';
	public static String productFamilleAppareils = 'Appareils';
	public static String productFamilleConsommables = 'Consommables';
	public static String productFamilleOutillage = 'Outillage';
	public static String productFamillePieceDetache = 'Pièces détachées';

	public static String productCodeCouvMoGarCham = 'COUV-MO-GAR-CHAM';
	public static String productCodeDeplZone = 'DEPL-ZONE';
	public static String productCodeCouvDeplGarCham = 'COUV-DEPL-GAR-CHAM';

	public static String productStatutApprouvee = 'Approuvée';

	//conditions variables
	public static String conditionRtLigne = 'Ligne';

	// Règlement variables
	public static String reglementStatutPaiementEncaisse = 'Encaissé';
	public static String reglementStatutPaiementCollecte = 'Collecté';

	//Service Contract variables
	// Contract_Status__c
	public static String serviceContractStatutContratAttenteRen = 'En attente de renouvellement';
	public static String serviceContractStatutContratActive = 'Active';
	public static String serviceContractStatutContratPendingPayment = 'Pending Payment';
	public static String serviceContractStatutContratResilie = 'Résilié';
	public static String serviceContractStatutContratExpired = 'Expired';
	public static String serviceContractStatutEnAttentePremiereVisitValid = 'Pending first visit';
	public static String serviceContractStatutActifenretarddepaiement = 'Actif - en retard de paiement';
	public static String serviceContractStatutResilieenretarddepaiement = 'Résiliation pour retard de paiement';
	public static String serviceContractStatutCancelled = 'Cancelled';
	public static String serviceContractStatutEnAttente = 'Pending Client Validation';

	//Service Contract variables
	//Recordtype DeveloperNAme
	public static String ContratsIndividuels = 'Contrats_Individuels';
	public static String ContratsCollectifPublic = 'Contrats_collectifs_publics';
	public static String ContratsCollectifPrives = 'Contrats_Collectifs_Prives';
	//Type__c
	public static String serviceContractTypeInd = 'Individual';
	public static String serviceContractTypeCollective = 'Collective';

	//ProductRequestLineItem variables
	public static String PRLIStatutReservePrep = 'Réservé à préparer';
	public static String PRLIStatutCommande = 'A commander';
	public static String PRLIStatutEnCourCommande = 'En cours de commande';
	public static String PRLIStatutAnnule	 = 'Annulé';
	public static String PRLIStatutResPrep = 'Réservé préparé';
	//contract line item variables:
	public static String cliStatusComplete = 'Complete';

	//LC78 Email template dev names
	public static String ET_ClientAyantUncompteExistant = 'ET_ClientAyantUncompteExistant';
	public static String ET_CompteNayantPasEmail = 'ET_CompteNayantPasEmail';
	public static String ET_ActivationClient = 'ET_ActivationClient';

	//LC78 Condition facture sofacto
	public static String TypePrestationRemplacement = 'remplacement';
	public static String TypePrestationVenteGuichet = 'Vente guichet';
	public static String TypePrestationMiseEnService = 'Mise en service';
	public static String TypePrestationVisiteForfaitaire = 'visite forfaitaire';
	public static String TypePrestationHorsGuichet = 'pièces hors guichet (SAV)';
	public static String TypePrestationAutres = 'autres';
	public static String StatusIssued = 'Emise';

	//LC78 Condition devis
	public static String StatusDraft = 'Draft';
	public static String StatusInReview = 'In Review';

	//GTL 24/05/2024 - BATCH DYNAMIC SOQL FILTER(BAT76)
	public static String constructDynamicFilter(List<SOQL_Filter__mdt> lstFilter) {
        String dynamicFilter = '';
        String fieldName;

        for (SOQL_Filter__mdt filter : lstFilter) {

            if (filter.Filter_Expression__c == 'LIKE') {
                dynamicFilter += constructLikeClause(filter.Filter_Type__c, filter.Filter_Value__c, false);
            } else if (filter.Filter_Expression__c == 'NOT LIKE') {
                dynamicFilter += constructLikeClause(filter.Filter_Type__c, filter.Filter_Value__c, true);
            } else if (filter.Filter_Expression__c == 'IN') {
                dynamicFilter += constructInClause(filter.Filter_Type__c, filter.Filter_Value__c, false);
            } else if (filter.Filter_Expression__c == 'NOT IN') {
                dynamicFilter += constructInClause(filter.Filter_Type__c, filter.Filter_Value__c, true);
            } else if (filter.Filter_Expression__c == '=') {
                dynamicFilter += constructEqualClause(filter.Filter_Type__c, filter.Filter_Value__c, filter.Filter_Value_String__c);
            } else if (filter.Filter_Expression__c == '!=') {
                dynamicFilter += constructNotEqualClause(filter.Filter_Type__c, filter.Filter_Value__c, filter.Filter_Value_String__c);
			}else if (filter.Filter_Expression__c == '<') {
                dynamicFilter += constructLessThanClause(filter.Filter_Type__c, filter.Filter_Value__c, false);
            } else if (filter.Filter_Expression__c == '>') {
                dynamicFilter += constructGreaterThanClause(filter.Filter_Type__c, filter.Filter_Value__c, false);
            } else if (filter.Filter_Expression__c == '>=') {
                dynamicFilter += constructGreaterThanClause(filter.Filter_Type__c, filter.Filter_Value__c, true);
            } else if (filter.Filter_Expression__c == '<=') {
                dynamicFilter += constructLessThanClause(filter.Filter_Type__c, filter.Filter_Value__c, true);
            }
        }

        return dynamicFilter;
    }

    public static String constructLikeClause(String fieldName, String values, Boolean isNot) {
        List<String> likeClauses = new List<String>();
        for (String value : values.split(',')) {
            String clause = fieldName + ' LIKE \'' + value.trim() + '\'';
            likeClauses.add(clause);
        }
		if (isNot) {
			return 'AND (NOT (' + String.join(likeClauses, ' OR ') + ')) ';
		}else{
			return 'AND (' + String.join(likeClauses, ' OR ') + ') ';
		}
    }

    public static String constructInClause(String fieldName, String values, Boolean isNot) {
        List<String> inClauses = new List<String>();
        for (String value : values.split(',')) {
            inClauses.add('\'' + value.trim() + '\'');
        }
        String clause = fieldName + ' IN (' + String.join(inClauses, ', ') + ')';
        if (isNot) {
            clause = fieldName + ' NOT IN (' + String.join(inClauses, ', ') + ')';
        }
        return 'AND ' + clause + ' ';
    }

    public static String constructEqualClause(String fieldName, String values, Boolean isString) {
        List<String> equalClauses = new List<String>();
        for (String value : values.split(',')) {
            if(!isString){
				String clause = fieldName + ' = ' + value.trim();
				equalClauses.add(clause);
			}else {
				String clause = fieldName + ' = ' + '\'' + value.trim() + '\'';
				equalClauses.add(clause);
			}
        }
        return 'AND (' + String.join(equalClauses, ' OR ') + ') ';
    }

    public static String constructNotEqualClause(String fieldName, String values, Boolean isString) {
        List<String> notEqualClauses = new List<String>();
        for (String value : values.split(',')) {
            if(!isString){
				String clause = fieldName + ' != ' + value.trim();
				notEqualClauses.add(clause);
			}else {
				String clause = fieldName + ' != ' + '\'' + value.trim() + '\'';
				notEqualClauses.add(clause);
			}
        }
        return 'AND (' + String.join(notEqualClauses, ' OR ') + ') ';
    }

    public static String constructLessThanClause(String fieldName, String values, Boolean equal) {
        List<String> lessThanClauses = new List<String>();
        String clause = '';
        for (String value : values.split(',')) {
            if(equal){
                clause = fieldName + ' <= ' + value.trim();
            }else{
                clause = fieldName + ' < ' + value.trim();
            }
            lessThanClauses.add(clause);
        }
        return 'AND (' + String.join(lessThanClauses, ' OR ') + ') ';
    }

    public static String constructGreaterThanClause(String fieldName, String values,  Boolean equal) {
        List<String> greaterThanClauses = new List<String>();
        String clause = '';
        for (String value : values.split(',')) {
            if(equal){
                clause = fieldName + ' >= ' + value.trim() ;
            }else{
                clause = fieldName + ' > ' + value.trim() ;
            }
            greaterThanClauses.add(clause);
        }
        return 'AND (' + String.join(greaterThanClauses, ' OR ') + ') ';
    }
	public static String truncateString(String input, Integer length) {
		if (input == null) {
			return '';
		}
		if (length == null) {
			return input;
		}
		if (input.length() <= length) {
			return input;
		}
		return input.substring(0, length);
    }
	public static String generateName(String pdfname,String format){
		// String pdfName = 'DocaposteXML';
		DateTime datToday = DateTime.now();
		pdfName += '-'+( datToday.day() < 10 ? '0'+datToday.day() : datToday.day().format());
		pdfName += '-'+(datToday.month() < 10 ? '0'+datToday.month() : datToday.month().format());
		pdfName += '-'+(datToday.year());
        pdfName += '-'+(datToday.hour() < 10 ? '0'+datToday.hour() : datToday.hour().format());
        pdfName += '-'+(datToday.minute() < 10 ? '0'+datToday.minute() : datToday.minute().format());
        pdfName += '-'+(datToday.second() < 10 ? '0'+datToday.second() : datToday.second().format());
		pdfName += '-'+(datToday.millisecond() < 10 ? '0'+datToday.millisecond() : datToday.millisecond().format());
        pdfName += format;
		return pdfName;
	}

	//GTL PHE-1496 11/07/2024
	public static String convertFrenchToEnglish(String input) {
        Map<String, String> frenchToEnglishMap = new Map<String, String>{
            'à' => 'a', 'â' => 'a', 'ä' => 'a', 'ç' => 'c', 'é' => 'e', 'è' => 'e', 'ê' => 'e', 'ë' => 'e',
            'î' => 'i', 'ï' => 'i', 'ô' => 'o', 'ö' => 'o', 'ù' => 'u', 'û' => 'u', 'ü' => 'u', 'ÿ' => 'y',
            'À' => 'A', 'Â' => 'A', 'Ä' => 'A', 'Ç' => 'C', 'É' => 'E', 'È' => 'E', 'Ê' => 'E', 'Ë' => 'E',
            'Î' => 'I', 'Ï' => 'I', 'Ô' => 'O', 'Ö' => 'O', 'Ù' => 'U', 'Û' => 'U', 'Ü' => 'U', 'Ÿ' => 'Y', 
            'æ' => 'a', 'œ' => 'o', 'Æ' => 'A', 'Œ' => 'O'
        };

        for (String frenchChar : frenchToEnglishMap.keySet()) {
            input = input.replaceAll(frenchChar, frenchToEnglishMap.get(frenchChar));
        }
        
        return input;
    }
}