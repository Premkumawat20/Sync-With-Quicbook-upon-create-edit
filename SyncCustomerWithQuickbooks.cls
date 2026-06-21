public with sharing class SyncCustomerWithQuickbooks {


   
    public static void createCustomer(QB_CustomerInput customer){
            
            // authorization bearer : token   
            // body post method 

             List<qb_Metadata__mdt>configList = [SELECT Id, DeveloperName, MasterLabel,  Environment__c, Prod_Base_URL__c, Sanbdox_Base_URL__c,
                                        access_token__c, auth_url__c, expires_in__c, expires_in_time__c, minorversion__c, Client_Id__c,Client_Secret__c,
                                        realmId__c, refresh_token__c, token_type__c, token_url__c 
                                        FROM qb_Metadata__mdt 
                                        WHERE DeveloperName = 'QBToken' 
                                        LIMIT 1 ];
            system.debug('config in createCustomer'+configList.get(0));
            qb_Metadata__mdt config=configList.get(0);
            if(configList.size()>0){
                Boolean isValid=PS_QBTokenUtil.isValid(config);
                system.debug('Outpuft of isValide'+isValid);
                Map<String,Object> fieldWithValuesMap;
                String accesstoken=config.access_token__c;

                if(!isValid){
                System.debug('In is before method'+fieldWithValuesMap);
                fieldWithValuesMap= PS_QBTokenUtil.refreshtoken(config);
                System.debug('In is Valid method'+fieldWithValuesMap);
                accesstoken=(String)fieldWithValuesMap.get('access_token__c');
                }
             
                //will prepare the request body to create customer in quick books
                //quick book to create a account is POST /v3/company/<realmID>/account
                HttpRequest httpreq=new HttpRequest();
                httpreq.setMethod('POST');
                httpreq.setHeader('Content-Type','application/json');
                httpreq.setHeader('Accept','application/json');
                httpreq.setHeader('Authorization', 'Bearer '+accesstoken);
                
                String endpoint=config.Sanbdox_Base_URL__c+'/v3/company/'+config.realmId__c+'/customer?minorversion='+config.minorversion__c;
                httpreq.setEndpoint(endpoint);
 
                String requestbody=System.JSON.serializePretty(customer);
                
                httpreq.setBody(requestbody);
                try{
                    HttpResponse httpres=(new Http()).send(httpreq);
                    if(httpres.getStatusCode() == 200 || httpres.getStatusCode() == 201){
                    Map<String, Object>res=(Map<String, Object>)System.JSON.deserializeUntyped(httpres.getBody());
                    Map<String,Object> customerResponse =(Map<String,Object>)res.get('Customer');
                    String customerId = String.valueOf(customerResponse.get('Id'));
                    system.debug('Inserted customer sucesfully'+customerId);
                    }
                    else{
                    System.debug(' httpRes getBody '+httpRes.getBody());
                    System.debug(' httpRes getStatusCode '+httpRes.getStatusCode());
                    }
                    
                }
                catch (Exception ex){
                    System.debug('Exception Executed '+ex);
                }
              
                //will update the metadata 
                if(fieldWithValuesMap?.size()>0){
                 system.debug('Updating the metadata...');
                 String fullName = 'qb_Metadata.QBToken';
                 String label    = 'QBToken';
                 CreateUpdateMetadataUtils.createUpdateMetadata(fullName, label, fieldWithValuesMap);

                }
            }
            else{
                System.debug('No Config found');
            }
    }

}