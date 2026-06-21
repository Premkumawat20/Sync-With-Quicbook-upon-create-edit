public with sharing class PS_QBTokenUtil {

public PageReference authorize(){
    qb_Metadata__mdt config = qb_Metadata__mdt.getAll().get('QBToken');
    if(config!=null){

    string redirect_uri=System.URL.getOrgDomainURL().toExternalForm()+'/apex/'+config.PageName__c;

        /* auth url 
    https://appcenter.intuit.com/connect/oauth2?
    client_id=Q3ylJatCvnkYqVKLmkxxxxxxxxxxxxxxxkYB36b5mws7HkKUEv9aI&response_type=code&
    scope=com.intuit.quickbooks.accounting&
    redirect_uri=https://www.mydemoapp.com/oauth-redirect&
    state=security_token%3D138r5719ru3e1%26url%3Dhttps://www.mydemoapp.com/oauth-redirect */
        
    String authorizeUrl = config.auth_url__c+'?client_id='+config.Client_Id__c+'&response_type=code'
                        +'&scope=openid profile email com.intuit.quickbooks.accounting com.intuit.quickbooks.payment'
                        +'&redirect_uri='+redirect_uri+'&state='+UserInfo.getOrganizationId()+redirect_uri;


    return new PageReference(authorizeUrl);
    
    }
    else{
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, 'Config not found' ));
        return null;
    }
}
public static void get_accessToken(){


    qb_Metadata__mdt config = qb_Metadata__mdt.getAll().get('QBToken');  
    
    if(config!=null){
        String code   = ApexPages.currentPage().getParameters().get('code');
        System.debug('code'+code);
        String realmId = ApexPages.currentPage().getParameters().get('realmId');
        HttpRequest httpreq =new HttpRequest();
        String redirect_uri=System.URL.getOrgDomainURL().toExternalForm()+'/apex/'+config.PageName__c;
        httpreq.setMethod('POST');
        httpreq.setHeader('Content-Type','application/x-www-form-urlencoded');
        httpreq.setHeader('Accept','application/json');
        httpreq.setEndpoint(config.token_url__c);
                            /* Body: grant_type=authorization_code&
                        code=L3114709614564VSU8JSEiPkXx1xhV8D9mv4xbv6sZJycibMUI&
                        redirect_uri=https://www.mydemoapp.com/oauth-redirect */
        String body='grant_type=authorization_code&code='+code+'&redirect_uri='+redirect_uri +'&client_id='+config.Client_Id__c+'&client_secret='+config.Client_Secret__c;
                
        
        httpreq.setBody(body);
        try{
            HttpResponse HttpRes= (new Http()).send(httpreq);
            if(HttpRes.getStatusCode()==201 || HttpRes.getStatusCode()==200){
                System.debug('Response:'+HttpRes.getBody());
            //  system.debug('preety'+)
            //parse the response
                Map<String,Object>responsetype= (Map<String,Object>)JSON.deserializeUntyped(HttpRes.getBody());
                String access_token = (String)responsetype.get('access_token');
                String refresh_token = (String)responsetype.get('refresh_token');
                Integer expires_in = (Integer)responsetype.get('expires_in');

            //prepare the map for the custom metadata
                
                //Map<String, Object> fieldWithValuesMap = prepareMetadata(httpRes.getBody(),'');
                String fullName = 'qb_Metadata.QBToken';
                String label    = 'QBToken';

                Map<String, Object> fieldWithValuesMap = new Map<String, Object>();
                fieldWithValuesMap.put('access_token__c', access_token);
                fieldWithValuesMap.put('expires_in__c',expires_in);
                fieldWithValuesMap.put('expires_in_time__c', System.now().addSeconds(expires_in) );
                fieldWithValuesMap.put('refresh_token__c', refresh_token);
                fieldWithValuesMap.put('realm_id__c', realmId);
                CreateUpdateMetadataUtils.createUpdateMetadata(fullName, label, fieldWithValuesMap);
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,'Successfull!'));

            //deply // upate the metadata

            }
            else{
                System.debug(HttpRes.getBody());
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, httpRes.getBody() ));

            }
            }
        
        catch(Exception ex ){
            system.debug(ex);
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, ex.getMessage() ));

        }
    } 
    else{
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, 'Config not found') );
        //return null;
    }

}

public static Boolean isValid(qb_Metadata__mdt config){
    if(config.expires_in_time__c <= System.Now()){
        return false;
    }
    return true;
}


public static Map<String, Object> refreshtoken(qb_Metadata__mdt config){
    /* for refresh token what we need to send an post request 
        Body: grant_type=refresh_toke&
        refresh_token=Q311488394272qbajGfLBwGmVsbF6VoNpUKaIO5oL49aXLVJUB */
    System.debug('Refresh Token');
    //System.debug('in Refresh token'+config);
    HttpRequest httpreq=new HttpRequest();
    httpreq.setMethod('POST');
    httpreq.setHeader('Content-Type','application/x-www-form-urlencoded');
    httpreq.setHeader('Accept','application/json');
    httpreq.setEndpoint(config.token_url__c);
   

    String reqbody =
    'grant_type=refresh_token' +
    '&client_id=' + config.Client_Id__c +
    '&client_secret=' + config.Client_Secret__c +
    '&refresh_token=' + config.refresh_token__c;

    httpreq.setBody(reqbody);
    System.debug('In Refresh token flow request body Is :'+reqbody);
    Map<String, Object> fieldWithValuesMap = new Map<String, Object>();
    try{
        HttpResponse httpres=(new Http()).send(httpreq);
        if(httpres.getStatusCode()>=200 && httpres.getStatusCode()<300){
            system.debug('Refresh token  || response body'+httpRes.getBody());
            fieldWithValuesMap = prepareMetadata(httpRes.getBody(),'');
        }
        else{
            system.debug('In Refresh token  || response body'+httpRes.getBody());
              System.debug('Status Code: ' + httpres.getStatusCode());
             //System.debug('Response Body: ' + httpres.getBody());
        }

    } 
        catch(Exception ex){
            system.debug('Error occured'+ex.getMessage());
        }
        system.debug('Refresh token : fieldwithValueMap'+fieldWithValuesMap);
        return fieldWithValuesMap; 

}

/**
 * @description Prepares metadata map from the OAuth response body for custom metadata creation/update
 * @param requestbody The JSON response body from the OAuth token request
 * @param realmId The QuickBooks realm ID (company ID) - optional parameter
 * @return Map<String,Object> A map containing access token, refresh token, expiry details for metadata update
 */
public static Map<String,Object> prepareMetadata(string requestbody, string realmId){
        Map<String, Object> responseMap =(Map<String, Object>)JSON.deserializeUntyped(requestbody);
        String access_token  = (String)responseMap.get('access_token');
        String refresh_token = (String)responseMap.get('refresh_token');
        Integer expires_in   = (Integer)responseMap.get('expires_in');
        
        Map<String, Object> fieldWithValuesMap = new Map<String, Object>();
        fieldWithValuesMap.put('access_token__c', access_token);
        fieldWithValuesMap.put('expires_in__c',expires_in);
        fieldWithValuesMap.put('expires_in_time__c', System.now().addSeconds(expires_in) );
        fieldWithValuesMap.put('refresh_token__c', refresh_token);

        if(!String.isBlank(realmId)){
        fieldWithValuesMap.put('realmId__c', realmId);
        }
    return fieldWithValuesMap;

}
}