-- =========================================================================
-- DUTHI E-COMMERCE: SCHEMA & VIEWS
-- =========================================================================
-- Autor: Thiago Costa
-- GitHub: github.com/thcosta-dados
-- Data: Fevereiro 2026
--
-- OBJETIVO:
-- Definição da estrutura de dados e criação de views otimizadas para
-- consumo no Power BI. Demonstra modelagem dimensional e boas práticas
-- de engenharia de dados.
--
-- CONTEÚDO:
-- 1. DDL (Data Definition Language)
--    - 3 tabelas (catalogo_produtos, pedidos, itens_vendidos)
--    - Constraints e Foreign Keys
--    - Indexes para otimização de queries
--
-- 2. Data Engineering
--    - Feature engineering (colunas temporais)
--    - Validações de integridade
--    - Cálculos derivados
--
-- 3. Views Otimizadas (9 views)
--    - Agregações pré-calculadas para performance
--    - Designed for Power BI consumption
--    - Star schema pattern
--
-- TÉCNICAS DEMONSTRADAS:
-- ✓ Modelagem dimensional
-- ✓ Normalização de dados
-- ✓ Indexação estratégica
-- ✓ Views materializadas
-- ✓ Data quality checks
-- =========================================================================

-- =========================================
-- TABELA 1: CATÁLOGO DE PRODUTOS
-- =========================================
CREATE TABLE catalogo_produtos (
    id_produto BIGINT PRIMARY KEY,
    nome_oficial VARCHAR(255) NOT NULL,
    categoria_principal VARCHAR(100),
    categoria_secundaria VARCHAR(100),
    categoria_terciaria VARCHAR(100),
    marca VARCHAR(100),
    estoque_atual INT DEFAULT 0,
    status_ativo INT DEFAULT 1
);

CREATE INDEX idx_produtos_categoria ON catalogo_produtos(categoria_principal);
CREATE INDEX idx_produtos_ativo ON catalogo_produtos(status_ativo);

-- =========================================
-- TABELA 2: PEDIDOS
-- =========================================
CREATE TABLE pedidos (
    id_pedido BIGINT PRIMARY KEY,
    data_pedido TIMESTAMP NOT NULL,
    id_cliente_anonimo VARCHAR(50),
    valor_total_pedido NUMERIC(10, 2) NOT NULL,
    valor_frete NUMERIC(10, 2) DEFAULT 0,
    ano_mes VARCHAR(7),
    dia_semana VARCHAR(10),
    mes INT,
    ano INT,
    trimestre INT
);

CREATE INDEX idx_pedidos_data ON pedidos(data_pedido);
CREATE INDEX idx_pedidos_cliente ON pedidos(id_cliente_anonimo);
CREATE INDEX idx_pedidos_ano_mes ON pedidos(ano_mes);

-- =========================================
-- TABELA 3: ITENS VENDIDOS
-- =========================================
CREATE TABLE itens_vendidos (
    id_item SERIAL PRIMARY KEY,
    id_pedido BIGINT NOT NULL,
    id_produto BIGINT NOT NULL,
    quantidade INT NOT NULL DEFAULT 1,
    preco_unitario_pago NUMERIC(10, 2) NOT NULL,
    valor_total_item NUMERIC(10, 2),
    CONSTRAINT fk_itens_pedido FOREIGN KEY (id_pedido) 
        REFERENCES pedidos(id_pedido) ON DELETE CASCADE,
    CONSTRAINT fk_itens_produto FOREIGN KEY (id_produto) 
        REFERENCES catalogo_produtos(id_produto) ON DELETE RESTRICT
);

CREATE INDEX idx_itens_pedido ON itens_vendidos(id_pedido);
CREATE INDEX idx_itens_produto ON itens_vendidos(id_produto);

-- =========================================
-- VERIFICAÇÃO
-- =========================================
SELECT 
    tablename,
    schemaname
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY tablename;

-- TUDO OK (JA VERIFICADO!) 

-- =========================================
-- PREENCHER AS COLUNAS DE TEMPO (Tabela Pedidos)
-- =========================================
-- 1. Aumentar o tamanho da coluna para caber os nomes inteiros
ALTER TABLE pedidos ALTER COLUMN dia_semana TYPE VARCHAR(20);

UPDATE pedidos
SET 
    dia_semana = CASE EXTRACT(DOW FROM data_pedido)
        WHEN 0 THEN 'Domingo'
        WHEN 1 THEN 'Segunda-feira'
        WHEN 2 THEN 'Terça-feira'
        WHEN 3 THEN 'Quarta-feira'
        WHEN 4 THEN 'Quinta-feira'
        WHEN 5 THEN 'Sexta-feira'
        WHEN 6 THEN 'Sábado'
    END;

-- 2. CALCULAR O TOTAL DO ITEM (Tabela Itens)
-- Multiplica quantidade pelo preço unitário para facilitar somas futuras
UPDATE itens_vendidos
SET valor_total_item = quantidade * preco_unitario_pago;

-- 3. CONFERÊNCIA
SELECT * FROM pedidos LIMIT 5;
SELECT * FROM itens_vendidos LIMIT 5;

-- =========================================
-- VALIDAÇÃO COMPLETA DO PROJETO
-- =========================================

-- 1. CONTAGENS GERAIS
SELECT 'Produtos' as tabela, COUNT(*) as total FROM catalogo_produtos
UNION ALL
SELECT 'Pedidos' as tabela, COUNT(*) as total FROM pedidos
UNION ALL
SELECT 'Itens Vendidos' as tabela, COUNT(*) as total FROM itens_vendidos;

-- 2. INTEGRIDADE (DEVE SER 0, 0)
SELECT 
    'Itens órfãos (sem pedido)' as problema,
    COUNT(*) as quantidade
FROM itens_vendidos i
LEFT JOIN pedidos p ON i.id_pedido = p.id_pedido
WHERE p.id_pedido IS NULL

UNION ALL

SELECT 
    'Itens órfãos (sem produto)' as problema,
    COUNT(*) as quantidade
FROM itens_vendidos i
LEFT JOIN catalogo_produtos c ON i.id_produto = c.id_produto
WHERE c.id_produto IS NULL;
-- OK! 

-- 3. FATURAMENTO TOTAL (CRÍTICO - deve bater ~R$ 16.500,00!)
SELECT 
    ROUND(SUM(valor_total_pedido), 2) as faturamento_bruto,
    ROUND(SUM(valor_frete), 2) as frete_total,
    ROUND(SUM(valor_total_pedido) + SUM(valor_frete), 2) as receita_total,
    ROUND(AVG(valor_total_pedido), 2) as ticket_medio,
    COUNT(*) as total_pedidos,
    MIN(data_pedido) as primeira_venda,
    MAX(data_pedido) as ultima_venda
FROM pedidos;
-- OK! Valor aproximado aceitável! 

-- 4. VERIFICAR FEATURE ENGINEERING
SELECT 
    COUNT(*) as total_pedidos,
    COUNT(ano_mes) as tem_ano_mes,
    COUNT(dia_semana) as tem_dia_semana,
    COUNT(mes) as tem_mes,
    COUNT(ano) as tem_ano,
    COUNT(trimestre) as tem_trimestre
FROM pedidos;

-- Todos devem ter o mesmo valor!
-- OK ! 

-- 5. VERIFICAR VALOR_TOTAL_ITEM
SELECT 
    COUNT(*) as total_itens,
    COUNT(valor_total_item) as tem_valor_calculado,
    SUM(CASE WHEN valor_total_item != quantidade * preco_unitario_pago THEN 1 ELSE 0 END) as calculos_errados
FROM itens_vendidos;

-- calculos_errados DEVE ser 0!
-- OK ! 

-- ========================================
-- VIEWS OTIMIZADAS PARA POWER BI
-- ========================================

-- VIEW 1: KPIs Principais (Dashboard Overview)
CREATE OR REPLACE VIEW vw_kpis_principais AS
SELECT 
    COUNT(DISTINCT id_pedido) as total_pedidos,
    COUNT(DISTINCT id_cliente_anonimo) as clientes_unicos,
    ROUND(SUM(valor_total_pedido), 2) as faturamento_bruto,
    ROUND(AVG(valor_total_pedido), 2) as ticket_medio,
    ROUND(SUM(valor_frete), 2) as frete_total,
    MIN(data_pedido) as primeira_venda,
    MAX(data_pedido) as ultima_venda
FROM pedidos;

-- VIEW 2: Vendas por Mês (Série Temporal)
CREATE OR REPLACE VIEW vw_vendas_mensais AS
SELECT 
    ano_mes,
    ano,
    mes,
    COUNT(*) as total_pedidos,
    ROUND(SUM(valor_total_pedido), 2) as faturamento_mensal,
    ROUND(AVG(valor_total_pedido), 2) as ticket_medio
FROM pedidos
GROUP BY ano_mes, ano, mes
ORDER BY ano_mes;

-- VIEW 3: Performance por Categoria
CREATE OR REPLACE VIEW vw_performance_categorias AS
SELECT 
    c.categoria_principal,
    COUNT(DISTINCT c.id_produto) as produtos_na_categoria,
    SUM(i.quantidade) as unidades_vendidas,
    ROUND(SUM(i.valor_total_item), 2) as receita_categoria,
    ROUND(AVG(i.preco_unitario_pago), 2) as preco_medio,
    ROUND(100.0 * SUM(i.valor_total_item) / SUM(SUM(i.valor_total_item)) OVER(), 2) as percentual_receita
FROM itens_vendidos i
JOIN catalogo_produtos c ON i.id_produto = c.id_produto
WHERE c.categoria_principal IS NOT NULL
GROUP BY c.categoria_principal;

-- VIEW 4: Top 20 Produtos
CREATE OR REPLACE VIEW vw_top_produtos AS
SELECT 
    c.nome_oficial,
    c.categoria_principal,
    SUM(i.quantidade) as quantidade_vendida,
    COUNT(DISTINCT i.id_pedido) as pedidos_contendo,
    ROUND(SUM(i.valor_total_item), 2) as receita_gerada,
    ROUND(AVG(i.preco_unitario_pago), 2) as preco_medio
FROM itens_vendidos i
JOIN catalogo_produtos c ON i.id_produto = c.id_produto
GROUP BY c.id_produto, c.nome_oficial, c.categoria_principal
ORDER BY receita_gerada DESC
LIMIT 20;

-- VIEW 5: Segmentação de Clientes
CREATE OR REPLACE VIEW vw_segmentacao_clientes AS
SELECT 
    CASE 
        WHEN numero_pedidos = 1 THEN 'Cliente Único (1 compra)'
        WHEN numero_pedidos = 2 THEN 'Cliente Recorrente (2 compras)'
        ELSE 'Cliente Fiel (3+ compras)'
    END as segmento,
    COUNT(*) as quantidade_clientes,
    ROUND(AVG(lifetime_value), 2) as valor_medio_cliente,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) as percentual
FROM (
    SELECT 
        id_cliente_anonimo,
        COUNT(*) as numero_pedidos,
        SUM(valor_total_pedido) as lifetime_value
    FROM pedidos
    WHERE id_cliente_anonimo != 'nao_informado'
    GROUP BY id_cliente_anonimo
) AS clientes
GROUP BY segmento
ORDER BY quantidade_clientes DESC;

-- VIEW 6: Performance por Dia da Semana
CREATE OR REPLACE VIEW vw_performance_dia_semana AS
SELECT 
    dia_semana,
    COUNT(*) as total_pedidos,
    ROUND(SUM(valor_total_pedido), 2) as faturamento,
    ROUND(AVG(valor_total_pedido), 2) as ticket_medio,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) as percentual_pedidos
FROM pedidos
GROUP BY dia_semana;

-- VIEW 7: Análise de Frete (Estratégia Logística)
CREATE OR REPLACE VIEW vw_analise_frete AS
SELECT 
    CASE 
        WHEN valor_frete = 0 THEN 'Frete Grátis'
        WHEN valor_frete > 0 AND valor_frete <= 15 THEN 'Frete Baixo (até R$15)'
        WHEN valor_frete > 15 AND valor_frete <= 30 THEN 'Frete Médio (R$15-30)'
        ELSE 'Frete Alto (> R$30)'
    END as faixa_frete,
    COUNT(id_pedido) as qtd_pedidos,
    ROUND(SUM(valor_total_pedido), 2) as faturamento_faixa,
    ROUND(AVG(valor_total_pedido), 2) as ticket_medio_faixa,
    ROUND(AVG(valor_frete), 2) as custo_medio_frete
FROM pedidos
GROUP BY 1 -- Agrupa pelo CASE (primeira coluna)
ORDER BY custo_medio_frete;

-- VIEW 8: Análise de Cesta (Cross-Selling)
CREATE OR REPLACE VIEW vw_analise_cesta AS
WITH itens_por_pedido AS (
    SELECT 
        id_pedido,
        SUM(quantidade) as total_itens
    FROM itens_vendidos
    GROUP BY id_pedido
)
SELECT 
    CASE 
        WHEN total_itens = 1 THEN '1 Item (Unitário)'
        WHEN total_itens = 2 THEN '2 Itens (Dupla)'
        WHEN total_itens BETWEEN 3 AND 5 THEN '3 a 5 Itens (Cesta Média)'
        ELSE '6+ Itens (Cesta Grande)'
    END as tamanho_cesta,
    COUNT(id_pedido) as qtd_pedidos,
    ROUND(100.0 * COUNT(id_pedido) / SUM(COUNT(id_pedido)) OVER(), 2) as percentual_pedidos
FROM itens_por_pedido
GROUP BY 1
ORDER BY qtd_pedidos DESC;

-- VIEW 9: Detalhe Geral (A "Tabela Principal" para Power BI)
CREATE OR REPLACE VIEW vw_fato_completa_powerbi as
SELECT 
    p.id_pedido,
    p.data_pedido,
    p.ano_mes,
    p.dia_semana,
    p.id_cliente_anonimo,
    p.valor_total_pedido,
    p.valor_frete,
    i.quantidade,
    i.preco_unitario_pago,
    i.valor_total_item,
    prod.nome_oficial as produto,
    prod.categoria_principal,
    prod.marca
FROM itens_vendidos i
JOIN pedidos p ON i.id_pedido = p.id_pedido
JOIN catalogo_produtos prod ON i.id_produto = prod.id_produto;

-- Verificar se as views foram criadas
SELECT table_name 
FROM information_schema.views 
WHERE table_schema = 'public'
ORDER BY table_name;

