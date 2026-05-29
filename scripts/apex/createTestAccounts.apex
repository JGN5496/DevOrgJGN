// Create 50 test accounts: 10 simple + 40 custom
List<Account> allAccounts = new List<Account>();

// Part 1: Create 10 simple accounts
for (Integer i = 0; i < 10; i++) {
    allAccounts.add(new Account(
        Name = 'Test Account ' + i,
        Industry = 'Technology',
        NumberOfEmployees = 100 + i
    ));
}

// Part 2: Create 40 custom accounts with varied data
String[] industries = new String[]{'Technology', 'Healthcare', 'Finance', 'Manufacturing', 'Retail', 'Energy', 'Telecommunications', 'Education'};
String[] types = new String[]{'Customer', 'Prospect', 'Partner', 'Customer', 'Prospect'};
String[] ratings = new String[]{'Hot', 'Warm', 'Cold', 'Hot', 'Warm'};
String[] cities = new String[]{'New York', 'Los Angeles', 'Chicago', 'Houston', 'Phoenix', 'Philadelphia', 'San Antonio', 'San Diego', 'Dallas', 'San Jose'};
String[] states = new String[]{'NY', 'CA', 'IL', 'TX', 'AZ', 'PA', 'TX', 'CA', 'TX', 'CA'};

for (Integer i = 0; i < 40; i++) {
    Account acc = new Account(
        Name = 'Custom Account ' + (i + 1),
        Industry = industries[Math.mod(i, industries.size())],
        Type = types[Math.mod(i, types.size())],
        Rating = ratings[Math.mod(i, ratings.size())],
        NumberOfEmployees = 50 + (i * 25),
        AnnualRevenue = 1000000 + (i * 500000),
        Phone = '555-' + String.valueOf(1000 + i).leftPad(4, '0'),
        BillingStreet = (100 + i) + ' Main Street',
        BillingCity = cities[Math.mod(i, cities.size())],
        BillingState = states[Math.mod(i, states.size())],
        BillingPostalCode = String.valueOf(10000 + i),
        BillingCountry = 'USA',
        Description = 'Custom test account created for demo purposes'
    );
    allAccounts.add(acc);
}

// Insert all 50 accounts
try {
    insert allAccounts;
    System.debug('Successfully created ' + allAccounts.size() + ' accounts');
    System.debug('Account IDs: ' + allAccounts);
    
    // Query to verify
    List<Account> verifyAccounts = [SELECT Id, Name, Industry, Type FROM Account WHERE Id IN :allAccounts ORDER BY Name];
    System.debug('Verification - Total accounts created: ' + verifyAccounts.size());
    for (Account a : verifyAccounts) {
        System.debug('Created: ' + a.Name + ' (' + a.Industry + ', ' + a.Type + ')');
    }
} catch (DmlException e) {
    System.debug('Error creating accounts: ' + e.getMessage());
}