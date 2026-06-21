public class QBCreateCustomerAction {

    @InvocableMethod(label='Create QuickBooks Customer' description='Syncs Quickbooks_Customers__c record to QuickBooks')
    public static void createCustomer(List<CustomerInput> inputs) {
        CustomerInput input = inputs.get(0);

        QBCustomerInput customer = new QBCustomerInput();
        customer.DisplayName        = input.quickbooksName;
        customer.FullyQualifiedName = input.quickbooksName;
        customer.GivenName          = input.givenName;
        customer.MiddleName         = input.middleName;
        customer.CompanyName        = input.companyName;
        customer.Notes              = input.notes;
        customer.Title              = input.title;
        customer.Suffix             = input.suffix;

        QBCustomerInput.PrimaryEmailAddr email = new QBCustomerInput.PrimaryEmailAddr();
        email.Address               = input.primaryEmail;
        customer.PrimaryEmailAddr   = email;

        QBCustomerInput.PrimaryPhone phone = new QBCustomerInput.PrimaryPhone();
        phone.FreeFormNumber        = input.primaryPhone;
        customer.PrimaryPhone       = phone;

        // Serialize and pass to @future to avoid callout-after-DML error
        String customerJson = System.JSON.serialize(customer);
        QBCreateCustomerAction.createCustomerAsync(customerJson);
    }

    @future(callout=true)
    public static void createCustomerAsync(String customerJson) {
        QBCustomerInput customer = (QBCustomerInput) System.JSON.deserialize(customerJson, QBCustomerInput.class);
        QBSyncCustomer.createCustomer(customer);
    }

    public class CustomerInput {
        @InvocableVariable(label='Quickbooks Name' required=true)
        public String quickbooksName;

        @InvocableVariable(label='Given Name')
        public String givenName;

        @InvocableVariable(label='Middle Name')
        public String middleName;

        @InvocableVariable(label='Company Name')
        public String companyName;

        @InvocableVariable(label='Primary Email')
        public String primaryEmail;

        @InvocableVariable(label='Primary Phone')
        public String primaryPhone;

        @InvocableVariable(label='Notes')
        public String notes;

        @InvocableVariable(label='Title')
        public String title;

        @InvocableVariable(label='Suffix')
        public String suffix;
    }
}