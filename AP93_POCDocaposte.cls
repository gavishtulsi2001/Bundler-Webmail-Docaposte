/**
 * @description       : 
 * @author            : ARM
 * @group             : 
 * @last modified on  : 01-31-2025
 * @last modified by  : Gavish Varma Tulsi
 * @Version           :  
 * Modifications Log
 * Ver   Date         Author   Modification
 * 1.0   31-01-2024   ARM   Initial Version
**/
public with sharing class AP93_POCDocaposte {
	public static Map<String,String> accessingTheWebservice(String xml) {

		String msg='';
		String filename = 'ChamServiceAppointment'+Datetime.now().format('dd_MM_yyyy_HH_mm_ss_SSS')+'.xml';
		HttpRequest tokenRequest = new HttpRequest();
		http req = new http();

		Utils__mdt utils = Utils__mdt.getInstance('IdPrestation');
		String idPrestationValue = '';

		if (utils?.IsActive__c) {
			idPrestationValue = utils.Value__c;
		}

		tokenRequest.setMethod('POST');
		tokenRequest.setEndpoint('callout:Docaposte/depot2editique/api/authenticate');
		tokenRequest.setHeader('Content-Type', 'application/json');
		string username = '{!$Credential.Docaposte.Username}';
		string password = '{!$Credential.Docaposte.Password}';
		String requestBody = '{"username": "' + username + '", "password": "' + password + '"}';
		tokenRequest.setBody(requestBody);

		httpResponse res = req.send(tokenRequest);

		if (res.getStatusCode() == 200) {
			String response = res.getBody();
			map<String, String> mapResponse = (Map<String, String>) JSON.deserialize(response, Map<String, String>.class);

			String token = mapResponse.get('id_token');

			String proprietes = '{"idPrestation": "' + idPrestationValue + '","type":"xml","nom":"' + fileName + '","idTransfert":"a9293b6c-2947-3e48-8db7-384e97a30693","infosClient":[{"champ":"idPerson","valeur":"c2693b6c-2947-3e48-8db7-384e97a30724"},{"champ":"idControl","valeur":"c2693b6c-2947-3e48-8db7-384e80a11111"}]}';

			string Boundary = '----------------------------1ff13444ed8140c7a32fc4e6451aa76d';
			string contentType = 'multipart/form-data; charset="UTF-8"; boundary="' + Boundary + '"';

			String headerForJSON = '--' + boundary + '\r\nContent-Disposition: form-data; name="proprietes" \r\nContent-Type: application/json \r\n\r\n' + proprietes + '\r\n\r\n';

			String headerForFile = '--' + boundary + '\r\nContent-Disposition: form-data; name="fichier"; filename="' + fileName + '"\r\nContent-Type: application/octet-stream \r\n\r\n' + xml + '\r\n\r\n';

			String footer = '\r\n--' + boundary + '--\r\n';

			String body = headerForJSON + headerForFile + footer;

			HttpRequest actualRequest = new httpRequest();
			actualRequest.setMethod('POST');

			actualRequest.setEndpoint('callout:DocaposteDepot');
			actualRequest.setHeader('Authorization', 'Bearer ' + token);
			actualRequest.setHeader('Content-Type', 'multipart/form-data; boundary=' + boundary);
			actualRequest.setHeader('User-Agent', 'TheUserJPA/1.0');
			actualRequest.setHeader('Accept', '*/*');
			actualRequest.setHeader('Connection', 'keep-alive');
			actualRequest.setBodyAsBlob(blob.valueOf(body));

			http req1 = new http();
			HTTPResponse res1 = req1.send(actualRequest);

			Map<String, Object> mapRes = (Map<String, Object>)JSON.deserializeUntyped(res1.getBody());
			msg=(String)MapRes.get('code')+ ':' +(String)MapRes.get('message')+':';
		} else {
			msg='Error:';
		}
		
	
		return new map<String,String>{
			'filename' => filename,
			'msg'=>msg
		};		
	}
}
