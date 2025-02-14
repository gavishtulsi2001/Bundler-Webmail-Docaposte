/**
 * @description       :
 * @author            : spoon
 * @group             :
 * @last modified on  : 02-05-2025
 * @last modified by  : Sambhav Bholah
 * @Version           :
 * Modifications Log
 * Ver   Date         Author   Modification
 * 1.0   30-07-2024   ARM   Initial Version
 **/
public without sharing class Utils {
  public static List<ContentDocumentLink> contentDocumentLinkListTest = new List<ContentDocumentLink>();
  public static Boolean isTest;

  // Retourne l'identifiant des comptes des users connectés
  public static map<String, String> getAccountIdFromCommunityUser(
    List<String> usersIds
  ) {
    System.debug('--- getAccountIdFromCommunityUser Start !');
    map<String, String> result = new Map<String, String>();
    List<String> contactsId = new List<String>();

    List<User> users = [
      SELECT Id, Name, ContactId
      FROM User
      WHERE Id IN :usersIds AND ContactId != NULL
    ];
    System.debug('--- users : ' + users);

    for (User anUser : users) {
      contactsId.add(anUser.ContactId);
    }

    if (contactsId.size() > 0) {
      for (Contact aContact : [
        SELECT Id, Name, AccountId
        FROM Contact
        WHERE Id IN :contactsId
        // AND IsPersonAccount = true
      ]) {
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
    List<ContentDocumentLink> contentDocumentLinkList = (test.isRunningTest() &&
      isTest)
      ? contentDocumentLinkListTest
      : [
          SELECT
            Id,
            LinkedEntityId,
            ContentDocumentId,
            ContentDocument.CreatedDate
          FROM ContentDocumentLink
          WHERE LinkedEntityId IN :recordsId
          // AND Visibility = 'AllUsers'
          // AND IsDeleted = False
          ORDER BY ContentDocument.CreatedDate DESC
        ];

    System.debug(
      '--- contentDocumentLinkList size: ' + contentDocumentLinkList.size()
    );

    if (
      contentDocumentLinkList.size() > 0 ||
      (contentDocumentLinkListTest.size() > 0 && isTest)
    ) {
      List<String> contentDocumentId = new List<String>();
      map<String, String> contentDistributionMap = new Map<String, String>();

      for (
        ContentDocumentLink aContentDocumentLink : (test.IsRunningTest() &&
          isTest)
          ? contentDocumentLinkListTest
          : contentDocumentLinkList
      ) {
        contentDocumentId.add(aContentDocumentLink.ContentDocumentId);
      }

      for (ContentDistribution aContentDistribution : [
        SELECT Id, ContentDocumentId, DistributionPublicUrl, CreatedDate
        FROM ContentDistribution
        WHERE ContentDocumentId IN :contentDocumentId
      ]) {
        if (!String.isBlank(aContentDistribution.DistributionPublicUrl)) {
          contentDistributionMap.put(
            aContentDistribution.ContentDocumentId,
            aContentDistribution.DistributionPublicUrl
          );
        }
      }

      for (ContentDocumentLink aContentDocumentLink : contentDocumentLinkList) {
        if (
          contentDistributionMap.containsKey(
            aContentDocumentLink.ContentDocumentId
          ) && !result.containsKey(aContentDocumentLink.LinkedEntityId)
        ) {
          result.put(
            aContentDocumentLink.LinkedEntityId,
            contentDistributionMap.get(aContentDocumentLink.ContentDocumentId)
          );
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
      map<String, String> userMap = Utils.getAccountIdFromCommunityUser(
        new List<String>{ theUserId }
      );

      if (userMap.containsKey(theUserId)) {
        result = [
          SELECT Id
          FROM Asset
          WHERE AccountId = :userMap.get(theUserId)
        ];
      }
    }

    System.debug('--- getUserAsset End !');
    return result;
  }

  // Retourne l'identifiant du record type d'un compte spécifié
  public static String getAccountRecordTypeId(String recordTypeLabel) {
    return Schema.SObjectType.Account.getRecordTypeInfosByName()
      .get(recordTypeLabel)
      .getRecordTypeId();
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
    return Datetime.newInstanceGmt(
      theDateTime.year(),
      theDateTime.month(),
      theDateTime.day(),
      theDateTime.hour(),
      theDateTime.minute(),
      theDateTime.second()
    );
  }

  // Envoie un email
//   public static void sendEmail(
//     String targetRecordId,
//     String templateId,
//     String displayerName
//   ) {
//     System.debug('--- targetRecordId : ' + targetRecordId);
//     System.debug('--- templateId : ' + templateId);

//     Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
//     mail.setTargetObjectId(targetRecordId);
//     mail.setSenderDisplayName(displayerName);
//     mail.setUseSignature(false);
//     mail.setBccSender(false);
//     mail.setSaveAsActivity(false);
//     mail.setTemplateId(templateId);
//     Messaging.SendEmailResult[] r = Messaging.sendEmail(
//       new List<Messaging.SingleEmailMessage>{ mail }
//     );
//   }

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
    Schema.SObjectType sObjectType = Schema.getGlobalDescribe()
      .get(sObjectName);

    if (sObjectType != null) {
      // Get the describe result for the SObject
      Schema.DescribeSObjectResult describeResult = sObjectType.getDescribe();

      // Get the fields map from the describe result
      Map<String, Schema.SObjectField> fieldMap = describeResult.fields.getMap();

      // Loop through the field map and populate the fieldsMap
      for (String fieldName : fieldMap.keySet()) {
        Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldName)
          .getDescribe();
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
    return ([
      SELECT Id
      FROM Profile
      WHERE name = 'Custom Customer Community_old'
    ]
    .Id);
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
    if (value != null) {
      Pattern regexPattern = Pattern.compile(regex);
      Matcher regexMatcher = regexPattern.matcher(value);
      // system.debug(value+'  '+regexMatcher.matches());
      return regexMatcher.matches();
    } else {
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

  //GTL 24/05/2024 - BATCH DYNAMIC SOQL FILTER(BAT76)
  public static String constructDynamicFilter(
    List<SOQL_Filter__mdt> lstFilter
  ) {
    String dynamicFilter = '';
    String fieldName;

    for (SOQL_Filter__mdt filter : lstFilter) {
      if (filter.Filter_Expression__c == 'LIKE') {
        dynamicFilter += constructLikeClause(
          filter.Filter_Type__c,
          filter.Filter_Value__c,
          false
        );
      } else if (filter.Filter_Expression__c == 'NOT LIKE') {
        dynamicFilter += constructLikeClause(
          filter.Filter_Type__c,
          filter.Filter_Value__c,
          true
        );
      } else if (filter.Filter_Expression__c == 'IN') {
        dynamicFilter += constructInClause(
          filter.Filter_Type__c,
          filter.Filter_Value__c,
          false
        );
      } else if (filter.Filter_Expression__c == 'NOT IN') {
        dynamicFilter += constructInClause(
          filter.Filter_Type__c,
          filter.Filter_Value__c,
          true
        );
      } else if (filter.Filter_Expression__c == '=') {
        dynamicFilter += constructEqualClause(
          filter.Filter_Type__c,
          filter.Filter_Value__c,
          filter.Filter_Value_String__c
        );
      } else if (filter.Filter_Expression__c == '!=') {
        dynamicFilter += constructNotEqualClause(
          filter.Filter_Type__c,
          filter.Filter_Value__c,
          filter.Filter_Value_String__c
        );
      } else if (filter.Filter_Expression__c == '<') {
        dynamicFilter += constructLessThanClause(
          filter.Filter_Type__c,
          filter.Filter_Value__c,
          false
        );
      } else if (filter.Filter_Expression__c == '>') {
        dynamicFilter += constructGreaterThanClause(
          filter.Filter_Type__c,
          filter.Filter_Value__c,
          false
        );
      } else if (filter.Filter_Expression__c == '>=') {
        dynamicFilter += constructGreaterThanClause(
          filter.Filter_Type__c,
          filter.Filter_Value__c,
          true
        );
      } else if (filter.Filter_Expression__c == '<=') {
        dynamicFilter += constructLessThanClause(
          filter.Filter_Type__c,
          filter.Filter_Value__c,
          true
        );
      }
    }

    return dynamicFilter;
  }

  public static String constructLikeClause(
    String fieldName,
    String values,
    Boolean isNot
  ) {
    List<String> likeClauses = new List<String>();
    for (String value : values.split(',')) {
      String clause = fieldName + ' LIKE \'' + value.trim() + '\'';
      likeClauses.add(clause);
    }
    if (isNot) {
      return 'AND (NOT (' + String.join(likeClauses, ' OR ') + ')) ';
    } else {
      return 'AND (' + String.join(likeClauses, ' OR ') + ') ';
    }
  }

  public static String constructInClause(
    String fieldName,
    String values,
    Boolean isNot
  ) {
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

  public static String constructEqualClause(
    String fieldName,
    String values,
    Boolean isString
  ) {
    List<String> equalClauses = new List<String>();
    for (String value : values.split(',')) {
      if (!isString) {
        String clause = fieldName + ' = ' + value.trim();
        equalClauses.add(clause);
      } else {
        String clause = fieldName + ' = ' + '\'' + value.trim() + '\'';
        equalClauses.add(clause);
      }
    }
    return 'AND (' + String.join(equalClauses, ' OR ') + ') ';
  }

  public static String constructNotEqualClause(
    String fieldName,
    String values,
    Boolean isString
  ) {
    List<String> notEqualClauses = new List<String>();
    for (String value : values.split(',')) {
      if (!isString) {
        String clause = fieldName + ' != ' + value.trim();
        notEqualClauses.add(clause);
      } else {
        String clause = fieldName + ' != ' + '\'' + value.trim() + '\'';
        notEqualClauses.add(clause);
      }
    }
    return 'AND (' + String.join(notEqualClauses, ' OR ') + ') ';
  }

  public static String constructLessThanClause(
    String fieldName,
    String values,
    Boolean equal
  ) {
    List<String> lessThanClauses = new List<String>();
    String clause = '';
    for (String value : values.split(',')) {
      if (equal) {
        clause = fieldName + ' <= ' + value.trim();
      } else {
        clause = fieldName + ' < ' + value.trim();
      }
      lessThanClauses.add(clause);
    }
    return 'AND (' + String.join(lessThanClauses, ' OR ') + ') ';
  }

  public static String constructGreaterThanClause(
    String fieldName,
    String values,
    Boolean equal
  ) {
    List<String> greaterThanClauses = new List<String>();
    String clause = '';
    for (String value : values.split(',')) {
      if (equal) {
        clause = fieldName + ' >= ' + value.trim();
      } else {
        clause = fieldName + ' > ' + value.trim();
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
//   public static String generateName(String pdfname, String format) {
//     // String pdfName = 'DocaposteXML';
//     DateTime datToday = DateTime.now();
//     pdfName +=
//       '-' +
//       (datToday.day() < 10 ? '0' + datToday.day() : datToday.day().format());
//     pdfName +=
//       '-' +
//       (datToday.month() < 10
//         ? '0' + datToday.month()
//         : datToday.month().format());
//     pdfName += '-' + (datToday.year());
//     pdfName +=
//       '-' +
//       (datToday.hour() < 10 ? '0' + datToday.hour() : datToday.hour().format());
//     pdfName +=
//       '-' +
//       (datToday.minute() < 10
//         ? '0' + datToday.minute()
//         : datToday.minute().format());
//     pdfName +=
//       '-' +
//       (datToday.second() < 10
//         ? '0' + datToday.second()
//         : datToday.second().format());
//     pdfName +=
//       '-' +
//       (datToday.millisecond() < 10
//         ? '0' + datToday.millisecond()
//         : datToday.millisecond().format());
//     pdfName += format;
//     return pdfName;
//   }

  //GTL PHE-1496 11/07/2024
  public static String convertFrenchToEnglish(String input) {
    Map<String, String> frenchToEnglishMap = new Map<String, String>{
      'à' => 'a',
      'â' => 'a',
      'ä' => 'a',
      'ç' => 'c',
      'é' => 'e',
      'è' => 'e',
      'ê' => 'e',
      'ë' => 'e',
      'î' => 'i',
      'ï' => 'i',
      'ô' => 'o',
      'ö' => 'o',
      'ù' => 'u',
      'û' => 'u',
      'ü' => 'u',
      'ÿ' => 'y',
      'À' => 'A',
      'Â' => 'A',
      'Ä' => 'A',
      'Ç' => 'C',
      'É' => 'E',
      'È' => 'E',
      'Ê' => 'E',
      'Ë' => 'E',
      'Î' => 'I',
      'Ï' => 'I',
      'Ô' => 'O',
      'Ö' => 'O',
      'Ù' => 'U',
      'Û' => 'U',
      'Ü' => 'U',
      'Ÿ' => 'Y',
      'æ' => 'a',
      'œ' => 'o',
      'Æ' => 'A',
      'Œ' => 'O'
    };

    for (String frenchChar : frenchToEnglishMap.keySet()) {
      input = input.replaceAll(frenchChar, frenchToEnglishMap.get(frenchChar));
    }

    return input;
  }
}
