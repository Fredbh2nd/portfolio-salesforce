@isTest
private class StockEngineTest {

    @testSetup
    static void setupData() {
        // Criação de dados de teste (Account, Opportunity, Product, Pricebook, etc.)
        Account acc = new Account(Name = 'Conta Teste Stock');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Oportunidade Teste',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id
        );
        insert opp;
    }

    @isTest
    static void testProcessStockAllocationSuccess() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        List<StockEngine.StockResult> results = StockEngine.processStockAllocation(new List<Id>{opp.Id});
        Test.stopTest();

        System.assertNotEquals(null, results, 'O resultado não deve ser nulo.');
    }
}
