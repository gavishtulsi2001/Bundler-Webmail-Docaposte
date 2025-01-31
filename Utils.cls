/**
 * @description       :
 * @author            : spoon
 * @group             :
 * @last modified on  : 29-10-2024
 * @last modified by  : ARM
 * @Version           :
 * Modifications Log
 * Ver   Date         Author   Modification
 * 1.0   30-07-2024   ARM   Initial Version
 **/
public without sharing class Utils {
	public static List<ContentDocumentLink> contentDocumentLinkListTest = new List<ContentDocumentLink>();
	public static Boolean isTest;

	// Retourne l'identifiant des comptes des users connectés
	public static map<String, String> getAccountIdFromCommunityUser(List<String> usersIds) {
		System.debug('--- getAccountIdFromCommunityUser Start !');
		map<String, String> result = new Map<String, String>();
		List<String> contactsId = new List<String>();

		List<User> users = [SELECT Id, Name, ContactId FROM User WHERE Id IN :usersIds AND ContactId != NULL];
		System.debug('--- users : ' + users);

		for (User anUser : users) {
			contactsId.add(anUser.ContactId);
		}

		if (contactsId.size() > 0) {
			for (
				Contact aContact : [
					SELECT Id, Name, AccountId
					FROM Contact
					WHERE Id IN :contactsId
					// AND IsPersonAccount = true
				]
			) {
				System.debug('--- aContact : ' + aContact);

				for (User anUser : users) {
					if (anUser.ContactId.equals(aContact.Id)) {
						result.put(anUser.Id, aContact.AccountId);

						break;
					}
				}
			}
		}

		System.debug('--- getAccountIdFromCommunityUser End !');

		return result;
	}

	// Retourne une map avec pour chaque enregistrement en clé, le lien du dernier document public en valeur
	public static map<String, String> getPublicLinkMap(List<String> recordsId) {
		System.debug('--- getPublicLinkMap Start !');

		map<String, String> result = new Map<String, String>();
		System.debug('--- recordsId size: ' + recordsId.size());
		System.debug('--- recordsId: ' + recordsId);

		// Récupération des ContentDocumentLinks des enregistrements demandés
		List<ContentDocumentLink> contentDocumentLinkList = (test.isRunningTest() && isTest)
			? contentDocumentLinkListTest
			: [
					SELECT Id, LinkedEntityId, ContentDocumentId, ContentDocument.CreatedDate
					FROM ContentDocumentLink
					WHERE LinkedEntityId IN :recordsId
					// AND Visibility = 'AllUsers'
					// AND IsDeleted = False
					ORDER BY ContentDocument.CreatedDate DESC
			  ];

		System.debug('--- contentDocumentLinkList size: ' + contentDocumentLinkList.size());

		if (contentDocumentLinkList.size() > 0 || (contentDocumentLinkListTest.size() > 0 && isTest)) {
			List<String> contentDocumentId = new List<String>();
			map<String, String> contentDistributionMap = new Map<String, String>();

			for (ContentDocumentLink aContentDocumentLink : (test.IsRunningTest() && isTest) ? contentDocumentLinkListTest : contentDocumentLinkList) {
				contentDocumentId.add(aContentDocumentLink.ContentDocumentId);
			}

			for (ContentDistribution aContentDistribution : [SELECT Id, ContentDocumentId, DistributionPublicUrl, CreatedDate FROM ContentDistribution WHERE ContentDocumentId IN :contentDocumentId]) {
				if (!String.isBlank(aContentDistribution.DistributionPublicUrl)) {
					contentDistributionMap.put(aContentDistribution.ContentDocumentId, aContentDistribution.DistributionPublicUrl);
				}
			}

			for (ContentDocumentLink aContentDocumentLink : contentDocumentLinkList) {
				if (contentDistributionMap.containsKey(aContentDocumentLink.ContentDocumentId) && !result.containsKey(aContentDocumentLink.LinkedEntityId)) {
					result.put(aContentDocumentLink.LinkedEntityId, contentDistributionMap.get(aContentDocumentLink.ContentDocumentId));
				}
			}
		}

		System.debug('--- result : ' + result);

		System.debug('--- getPublicLinkMap End !');

		return result;
	}

	// Retourne la liste des équipements de l'utilisateur connecté
	public static List<Asset> getUserAsset(String theUserId) {
		System.debug('--- getUserAsset Start !');

		List<Asset> result;

		if (!String.isBlank(theUserId)) {
			map<String, String> userMap = Utils.getAccountIdFromCommunityUser(new List<String>{ theUserId });

			if (userMap.containsKey(theUserId)) {
				result = [SELECT Id FROM Asset WHERE AccountId = :userMap.get(theUserId)];
			}
		}

		System.debug('--- getUserAsset End !');
		return result;
	}

	// Retourne l'identifiant du record type d'un compte spécifié
	public static String getAccountRecordTypeId(String recordTypeLabel) {
		return Schema.SObjectType.Account.getRecordTypeInfosByName().get(recordTypeLabel).getRecordTypeId();
	}

	// Nettoie une valeur d'un formulaire
	public static String cleanValue(String theValue) {
		String result;

		if (!String.isBlank(theValue)) {
			result = String.escapeSingleQuotes(theValue.trim());
		}

		return result;
	}

	// Convertie une date UTC en GMT
	public static DateTime fromUTCToGMT(DateTime theDateTime) {
		return Datetime.newInstanceGmt(theDateTime.year(), theDateTime.month(), theDateTime.day(), theDateTime.hour(), theDateTime.minute(), theDateTime.second());
	}

	// Envoie un email
	public static void sendEmail(String targetRecordId, String templateId, String displayerName) {
		System.debug('--- targetRecordId : ' + targetRecordId);
		System.debug('--- templateId : ' + templateId);

		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		mail.setTargetObjectId(targetRecordId);
		mail.setSenderDisplayName(displayerName);
		mail.setUseSignature(false);
		mail.setBccSender(false);
		mail.setSaveAsActivity(false);
		mail.setTemplateId(templateId);
		Messaging.SendEmailResult[] r = Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
	}

	/**
	 * @description perform division without throwing maths error
	 * @author ARM | 08-07-2024
	 * @param Decimal dividend
	 * @param Decimal divisor
	 * @return Decimal
	 **/
	public static Decimal safeDivision(Decimal dividend, Decimal divisor) {
		if (dividend == null || divisor == null || divisor == 0) {
			return 0;
		}
		return dividend / divisor;
	}

	/**
	 * @description perform safe multiplication
	 * @author ARM | 31-07-2024
	 * @param Decimal a
	 * @param Decimal b
	 * @return Decimal
	 **/
	public static Decimal safeMultiplication(Decimal a, Decimal b) {
		if (a == null || b == null) {
			return 0;
		}
		return a * b;
	}

	/**
	 * @description Dynamically get all fields related to an object
	 * @author ARM | 30-07-2024
	 * @param String sObjectName
	 * @return Map<String, String>
	 **/
	public static Map<String, String> getSObjectFields(String sObjectName) {
		Map<String, String> fieldsMap = new Map<String, String>();

		// Describe the SObject
		Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(sObjectName);

		if (sObjectType != null) {
			// Get the describe result for the SObject
			Schema.DescribeSObjectResult describeResult = sObjectType.getDescribe();

			// Get the fields map from the describe result
			Map<String, Schema.SObjectField> fieldMap = describeResult.fields.getMap();

			// Loop through the field map and populate the fieldsMap
			for (String fieldName : fieldMap.keySet()) {
				Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldName).getDescribe();
				fieldsMap.put(fieldName, fieldDescribe.getType().name());
			}
		} else {
			System.debug('SObject with name ' + sObjectName + ' does not exist.');
		}

		return fieldsMap;
	}

	/**
	 * @description get profileId community
	 * @author Gavish Varma Tulsi | 07-08-2024
	 * @return id
	 **/
	public static id getProfileCommunityId() {
		return ([SELECT Id FROM Profile WHERE name = 'Custom Customer Community_old'].Id);
	}

	/**
	 * @description get profileId by username
	 * @author Gavish Varma Tulsi | 07-08-2024
	 * @param List<String> names
	 * @return Map<String, Id>
	 **/
	public static Map<String, Id> getProfileIdByUsername(List<String> names) {
		Map<String, Id> nameByProfileId = new Map<String, Id>();
		for (User u : [SELECT Name, ProfileId FROM User WHERE Name IN :names]) {
			nameByProfileId.put(u.Name, u.ProfileId);
		}

		return nameByProfileId;
	}
  /**
  * @description takes in a regex and value as parameters and return whether it is valid or not 
  * @author JPA | 14-10-2024 
  * @param String regex 
  * @param String value 
  * @return Boolean 
  **/
  public static Boolean checkRegex(String regex, String value) {
		// System.debug(' REGEX  >>'+regex);
		if(value!=null){
		Pattern regexPattern = Pattern.compile(regex);
		Matcher regexMatcher = regexPattern.matcher(value);
		// system.debug(value+'  '+regexMatcher.matches());
		return regexMatcher.matches();
		}else{
		return false;
		}
	}

	/**
	* @description get profileId by Profile Name
	* @author Gavish Varma Tulsi | 10-24-2024 
	* @param names 
	* @return Map<String, Id> 
	**/
	public static Map<String, Id> getProfileIdByName(List<String> names) {
		Map<String, Id> nameByProfileId = new Map<String, Id>();
		for (Profile p : [SELECT Id, Name FROM Profile WHERE Name IN :names]) {
			nameByProfileId.put(p.Name, p.Id);
		}

		return nameByProfileId;
	}
}