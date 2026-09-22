@SuppressWarnings('PMD.ApexDoc')
public with sharing class StockEngine {
    public class StockResult {
        @InvocableVariable(label = 'Sucesso na Alocação' required = true)
        public Boolean isSuccess;

        @InvocableVariable(label = 'Mensagem de Retorno')
        public String statusMessage;
    }

    @InvocableMethod(Label = 'Processar Alocação de Estoque' description = 'Calcula e atualiza o estoque com base nos itens da Oportunidade.')
    public static List<StockResult> processStockAllocation(List<Id> opportunityIds) {
        List<StockResult> results = new List<StockResult>();

        // 1. Busca os produtos que pertencem às Oportunidades recebidas
        List<OpportunityLineItem> opportunityProducts = [
            SELECT Id, Product2Id, Quantity 
            FROM OpportunityLineItem 
            WHERE OpportunityId IN :opportunityIds
            WITH USER_MODE
        ];

        // 2. Coleta os IDs únicos dos produtos vendidos
        Set<Id> productIds = new Set<Id>();
        for (OpportunityLineItem oli : opportunityProducts) {
            productIds.add(oli.Product2Id);
        }

        // 3. Busca os estoques desses produtos e TRAVA os registros no banco
        List<Estoque__c> correntStocks = [
            SELECT Id, Produto__c, Quantidade_Disponivel__c, Quantidade_Reservada__c
            FROM Estoque__c
            WHERE Produto__c IN :productIds
            WITH USER_MODE
            FOR UPDATE
        ];

        // 4. MAPEAR O ESTOQUE (Dicionário de busca rápida)
        Map<Id, Estoque__c> stockByProductId = new Map<Id, Estoque__c>();
        for (Estoque__c est : correntStocks) {
            stockByProductId.put(est.Produto__c, est);
        }

        // Instancia as variáveis de retorno
        StockResult v_result = new StockResult();
        v_result.isSuccess = true;
        v_result.statusMessage = 'Alocação realizada com sucesso para todos os itens!';

        List<Estoque__c> stocksToUpdate = new List<Estoque__c>();

        // 5. O LOOP PROCESSADOR (Validação e cálculo)
        for (OpportunityLineItem oli : opportunityProducts) {
            Estoque__c estoqueDoProduto = stockByProductId.get(oli.Product2Id);

            if (estoqueDoProduto != null && estoqueDoProduto.Quantidade_Disponivel__c >= oli.Quantity) {
                // Realiza as subtrações e somas lógicas
                estoqueDoProduto.Quantidade_Disponivel__c -= oli.Quantity;
                estoqueDoProduto.Quantidade_Reservada__c += oli.Quantity;
                
                stocksToUpdate.add(estoqueDoProduto);
            } else {
                // Caso falte estoque para qualquer item, barra tudo
                v_result.isSuccess = false;
                v_result.statusMessage = 'Erro: Saldo insuficiente em estoque para um ou mais produtos.';
                break;
            }
        }

        // 6. O UPDATE (DML) - Só salva se tudo estiver correto
        if (v_result.isSuccess && !stocksToUpdate.isEmpty()) {
            update as user stocksToUpdate;
        }

        results.add(v_result);
        return results;
    }
}





