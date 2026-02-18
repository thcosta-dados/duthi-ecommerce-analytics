-- =========================================================================
-- DUTHI E-COMMERCE: ANÁLISES EXPLORATÓRIAS (EDA)
-- =========================================================================
-- Autor: Thiago Costa
-- GitHub: github.com/thcosta-dados
-- Data: Fevereiro 2026
--
-- OBJETIVO:
-- Exploração analítica de dados para descoberta de insights de negócio.
-- Este processo revelou os principais achados que orientaram a construção
-- do dashboard executivo e estratégias de crescimento.
--
-- PRINCIPAIS DESCOBERTAS:
-- 93% de churn (taxa de retenção: 7%)
-- Concentração em categoria Brincos (42% da receita)
-- Quinta e sexta-feira são 35% mais performáticos
-- Prata 925 representa 61.8% do mix de produtos
-- Frete grátis em 58% dos pedidos (estratégia validada)
--
-- ESTRUTURA:
-- Bloco 1: KPIs e Métricas Fundamentais
-- Bloco 2: Análise Temporal (sazonalidade, growth)
-- Bloco 3: Análise de Produtos (categorias, ranking)
-- Bloco 4: Análise de Clientes (segmentação, cohort)
-- Bloco 5: Análise de Performance (frete, cesta, ticket)
-- Bloco 6: SQL Avançado (window functions, CTEs, moving avg)
--
-- TÉCNICAS SQL AVANÇADAS:
-- Window Functions (RANK, LAG, AVG OVER)
-- Common Table Expressions (CTEs)
-- Cohort Analysis (retenção temporal)
-- Moving Averages (média móvel 3 meses)
-- Complex JOINs e Subqueries
-- Advanced GROUP BY com CASE statements
--
-- TOTAL: 19 queries organizadas em 6 blocos temáticos
-- =========================================================================

-- =========================================
-- BLOCO 1: KPIs(Key Performance Indicators) 
-- =========================================

-- 1.1 Resumo Executivo Geral
SELECT 
    COUNT(DISTINCT id_pedido) as total_pedidos,
    COUNT(DISTINCT id_cliente_anonimo) as clientes_unicos,
    ROUND(SUM(valor_total_pedido), 2) as faturamento_bruto,
    ROUND(SUM(valor_frete), 2) as frete_total,
    ROUND(SUM(valor_total_pedido) + SUM(valor_frete), 2) as receita_total,
    ROUND(AVG(valor_total_pedido), 2) as ticket_medio,
    ROUND(AVG(valor_frete), 2) as frete_medio,
    MIN(data_pedido) as primeira_venda,
    MAX(data_pedido) as ultima_venda,
    MAX(data_pedido)::date - MIN(data_pedido)::date as dias_operacao
FROM pedidos;


-- 1.2 Total de Itens Vendidos
SELECT 
    COUNT(*) as total_itens_vendidos,
    SUM(quantidade) as quantidade_total_produtos,
    ROUND(AVG(quantidade), 2) as itens_medio_por_linha,
    ROUND(AVG(preco_unitario_pago), 2) as preco_medio_unitario
FROM itens_vendidos;


-- 1.3 Pedidos por Mês (Evolução Temporal)
SELECT 
    ano_mes,
    COUNT(*) as total_pedidos,
    ROUND(SUM(valor_total_pedido), 2) as faturamento_mensal,
    ROUND(AVG(valor_total_pedido), 2) as ticket_medio_mensal,
    ROUND(SUM(valor_frete), 2) as frete_mensal
FROM pedidos
GROUP BY ano_mes
ORDER BY ano_mes;


-- =========================================
-- BLOCO 2: ANÁLISE TEMPORAL
-- =========================================

-- 2.1 Performance por Dia da Semana
SELECT 
    dia_semana,
    COUNT(*) as total_pedidos,
    ROUND(SUM(valor_total_pedido), 2) as faturamento_total,
    ROUND(AVG(valor_total_pedido), 2) as ticket_medio,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) as percentual_pedidos
FROM pedidos
GROUP BY dia_semana
ORDER BY 
    CASE dia_semana
        WHEN 'Domingo' THEN 0
        WHEN 'Segunda-feira' THEN 1
        WHEN 'Terça-feira' THEN 2
        WHEN 'Quarta-feira' THEN 3
        WHEN 'Quinta-feira' THEN 4
        WHEN 'Sexta-feira' THEN 5
        WHEN 'Sábado' THEN 6
    END;


-- 2.2 Performance por Trimestre
SELECT 
    ano,
    trimestre,
    COUNT(*) as total_pedidos,
    ROUND(SUM(valor_total_pedido), 2) as faturamento_trimestral,
    ROUND(AVG(valor_total_pedido), 2) as ticket_medio
FROM pedidos
GROUP BY ano, trimestre
ORDER BY ano, trimestre;


-- 2.3 Crescimento Mês a Mês (MoM Growth)
WITH vendas_mensais AS (
    SELECT 
        ano_mes,
        COUNT(*) as pedidos,
        ROUND(SUM(valor_total_pedido), 2) as faturamento
    FROM pedidos
    GROUP BY ano_mes
)
SELECT 
    ano_mes,
    pedidos,
    faturamento,
    LAG(faturamento) OVER (ORDER BY ano_mes) as faturamento_mes_anterior,
    ROUND(
        100.0 * (faturamento - LAG(faturamento) OVER (ORDER BY ano_mes)) 
        / NULLIF(LAG(faturamento) OVER (ORDER BY ano_mes), 0), 
        2
    ) as crescimento_percentual
FROM vendas_mensais
ORDER BY ano_mes;


-- =========================================
-- BLOCO 3: ANÁLISE DE PRODUTOS
-- =========================================

-- 3.1 Top 10 Produtos Mais Vendidos (por quantidade)
SELECT 
    c.nome_oficial,
    c.categoria_principal,
    SUM(i.quantidade) as quantidade_vendida,
    COUNT(DISTINCT i.id_pedido) as pedidos_contendo,
    ROUND(SUM(i.valor_total_item), 2) as receita_gerada,
    ROUND(AVG(i.preco_unitario_pago), 2) as preco_medio_venda
FROM itens_vendidos i
JOIN catalogo_produtos c ON i.id_produto = c.id_produto
GROUP BY c.id_produto, c.nome_oficial, c.categoria_principal
ORDER BY quantidade_vendida DESC
LIMIT 10;


-- 3.2 Top 10 Produtos por Receita
SELECT 
    c.nome_oficial,
    c.categoria_principal,
    SUM(i.quantidade) as quantidade_vendida,
    ROUND(SUM(i.valor_total_item), 2) as receita_total,
    ROUND(AVG(i.preco_unitario_pago), 2) as preco_medio
FROM itens_vendidos i
JOIN catalogo_produtos c ON i.id_produto = c.id_produto
GROUP BY c.id_produto, c.nome_oficial, c.categoria_principal
ORDER BY receita_total DESC
LIMIT 10;


-- 3.3 Performance por Categoria de Produto
SELECT 
    c.categoria_principal,
    COUNT(DISTINCT c.id_produto) as produtos_na_categoria,
    SUM(i.quantidade) as unidades_vendidas,
    ROUND(SUM(i.valor_total_item), 2) as receita_categoria,
    ROUND(AVG(i.preco_unitario_pago), 2) as preco_medio_categoria,
    ROUND(100.0 * SUM(i.valor_total_item) / SUM(SUM(i.valor_total_item)) OVER(), 2) as percentual_receita
FROM itens_vendidos i
JOIN catalogo_produtos c ON i.id_produto = c.id_produto
WHERE c.categoria_principal IS NOT NULL
GROUP BY c.categoria_principal
ORDER BY receita_categoria DESC;


-- 3.4 Produtos com Melhor Desempenho (Volume x Receita)
SELECT 
    c.nome_oficial,
    c.categoria_principal,
    SUM(i.quantidade) as qtd_vendida,
    ROUND(SUM(i.valor_total_item), 2) as receita,
    ROUND(SUM(i.valor_total_item) / SUM(i.quantidade), 2) as receita_por_unidade
FROM itens_vendidos i
JOIN catalogo_produtos c ON i.id_produto = c.id_produto
GROUP BY c.id_produto, c.nome_oficial, c.categoria_principal
HAVING SUM(i.quantidade) >= 3  -- Filtro: vendeu pelo menos 3 unidades
ORDER BY receita_por_unidade DESC
LIMIT 15;


-- =========================================
-- BLOCO 4: ANÁLISE DE CLIENTES
-- =========================================

-- 4.1 Segmentação de Clientes por Frequência
SELECT 
    numero_pedidos,
    COUNT(*) as quantidade_clientes,
    ROUND(AVG(valor_total_gasto), 2) as gasto_medio,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) as percentual_clientes
FROM (
    SELECT 
        id_cliente_anonimo,
        COUNT(*) as numero_pedidos,
        SUM(valor_total_pedido) as valor_total_gasto
    FROM pedidos
    WHERE id_cliente_anonimo != 'nao_informado'
    GROUP BY id_cliente_anonimo
) AS clientes_agrupados
GROUP BY numero_pedidos
ORDER BY numero_pedidos;


-- 4.2 Top 10 Clientes por Faturamento
SELECT 
    id_cliente_anonimo,
    COUNT(*) as total_pedidos,
    ROUND(SUM(valor_total_pedido), 2) as lifetime_value,
    ROUND(AVG(valor_total_pedido), 2) as ticket_medio_cliente,
    MIN(data_pedido) as primeira_compra,
    MAX(data_pedido) as ultima_compra,
    MAX(data_pedido)::date - MIN(data_pedido)::date as dias_como_cliente
FROM pedidos
WHERE id_cliente_anonimo != 'nao_informado'
GROUP BY id_cliente_anonimo
ORDER BY lifetime_value DESC
LIMIT 10;


-- 4.3 Análise de Recorrência (Clientes Novos vs Recorrentes por Mês)
WITH primeira_compra AS (
    SELECT 
        id_cliente_anonimo,
        MIN(ano_mes) as mes_primeira_compra
    FROM pedidos
    WHERE id_cliente_anonimo != 'nao_informado'
    GROUP BY id_cliente_anonimo
)
SELECT 
    p.ano_mes,
    COUNT(DISTINCT CASE WHEN p.ano_mes = pc.mes_primeira_compra THEN p.id_cliente_anonimo END) as clientes_novos,
    COUNT(DISTINCT CASE WHEN p.ano_mes != pc.mes_primeira_compra THEN p.id_cliente_anonimo END) as clientes_recorrentes,
    COUNT(DISTINCT p.id_cliente_anonimo) as total_clientes_mes
FROM pedidos p
LEFT JOIN primeira_compra pc ON p.id_cliente_anonimo = pc.id_cliente_anonimo
WHERE p.id_cliente_anonimo != 'nao_informado'
GROUP BY p.ano_mes
ORDER BY p.ano_mes;


-- =========================================
-- BLOCO 5: ANÁLISE DE PERFORMANCE
-- =========================================

-- 5.1 Análise de Frete (Impacto no Ticket)
SELECT 
    CASE 
        WHEN valor_frete = 0 THEN 'Frete Grátis'
        WHEN valor_frete > 0 AND valor_frete <= 10 THEN 'Frete Baixo (até R$10)'
        WHEN valor_frete > 10 AND valor_frete <= 15 THEN 'Frete Médio (R$10-15)'
        ELSE 'Frete Alto (acima R$15)'
    END as faixa_frete,
    COUNT(*) as total_pedidos,
    ROUND(AVG(valor_total_pedido), 2) as ticket_medio,
    ROUND(AVG(valor_frete), 2) as frete_medio,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) as percentual_pedidos
FROM pedidos
GROUP BY 
    CASE 
        WHEN valor_frete = 0 THEN 'Frete Grátis'
        WHEN valor_frete > 0 AND valor_frete <= 10 THEN 'Frete Baixo (até R$10)'
        WHEN valor_frete > 10 AND valor_frete <= 15 THEN 'Frete Médio (R$10-15)'
        ELSE 'Frete Alto (acima R$15)'
    END
ORDER BY frete_medio;


-- 5.2 Itens por Pedido (Análise de Cesta)
SELECT 
    itens_no_pedido,
    COUNT(*) as quantidade_pedidos,
    ROUND(AVG(valor_total), 2) as ticket_medio,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) as percentual_pedidos
FROM (
    SELECT 
        p.id_pedido,
        COUNT(i.id_item) as itens_no_pedido,
        p.valor_total_pedido as valor_total
    FROM pedidos p
    JOIN itens_vendidos i ON p.id_pedido = i.id_pedido
    GROUP BY p.id_pedido, p.valor_total_pedido
) AS pedidos_analisados
GROUP BY itens_no_pedido
ORDER BY itens_no_pedido;


-- 5.3 Distribuição de Ticket (Faixas de Valor)
SELECT 
    CASE 
        WHEN valor_total_pedido < 50 THEN 'Até R$ 50'
        WHEN valor_total_pedido >= 50 AND valor_total_pedido < 100 THEN 'R$ 50 - R$ 100'
        WHEN valor_total_pedido >= 100 AND valor_total_pedido < 150 THEN 'R$ 100 - R$ 150'
        WHEN valor_total_pedido >= 150 AND valor_total_pedido < 200 THEN 'R$ 150 - R$ 200'
        ELSE 'Acima de R$ 200'
    END as faixa_ticket,
    COUNT(*) as quantidade_pedidos,
    ROUND(SUM(valor_total_pedido), 2) as faturamento_faixa,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) as percentual_pedidos
FROM pedidos
GROUP BY 
    CASE 
        WHEN valor_total_pedido < 50 THEN 'Até R$ 50'
        WHEN valor_total_pedido >= 50 AND valor_total_pedido < 100 THEN 'R$ 50 - R$ 100'
        WHEN valor_total_pedido >= 100 AND valor_total_pedido < 150 THEN 'R$ 100 - R$ 150'
        WHEN valor_total_pedido >= 150 AND valor_total_pedido < 200 THEN 'R$ 150 - R$ 200'
        ELSE 'Acima de R$ 200'
    END
ORDER BY MIN(valor_total_pedido);


-- =========================================
-- BLOCO 6: QUERIES AVANÇADAS (Demonstração Técnica)
-- =========================================

-- 6.1 Ranking de Produtos por Categoria (Window Function)
SELECT 
    categoria_principal,
    nome_oficial,
    receita_total,
    ranking_na_categoria
FROM (
    SELECT 
        c.categoria_principal,
        c.nome_oficial,
        ROUND(SUM(i.valor_total_item), 2) as receita_total,
        RANK() OVER (PARTITION BY c.categoria_principal ORDER BY SUM(i.valor_total_item) DESC) as ranking_na_categoria
    FROM itens_vendidos i
    JOIN catalogo_produtos c ON i.id_produto = c.id_produto
    WHERE c.categoria_principal IS NOT NULL
    GROUP BY c.categoria_principal, c.nome_oficial
) AS ranked
WHERE ranking_na_categoria <= 3  -- Top 3 por categoria
ORDER BY categoria_principal, ranking_na_categoria;


-- 6.2 Análise de Cohort Simplificada (Retenção por Mês de Aquisição)
WITH primeira_compra_cliente AS (
    SELECT 
        id_cliente_anonimo,
        DATE_TRUNC('month', MIN(data_pedido)) as mes_cohort
    FROM pedidos
    WHERE id_cliente_anonimo != 'nao_informado'
    GROUP BY id_cliente_anonimo
),
vendas_com_cohort AS (
    SELECT 
        pc.mes_cohort,
        DATE_TRUNC('month', p.data_pedido) as mes_compra,
        p.id_cliente_anonimo,
        p.valor_total_pedido
    FROM pedidos p
    JOIN primeira_compra_cliente pc ON p.id_cliente_anonimo = pc.id_cliente_anonimo
)
SELECT 
    TO_CHAR(mes_cohort, 'YYYY-MM') as cohort,
    COUNT(DISTINCT CASE WHEN mes_cohort = mes_compra THEN id_cliente_anonimo END) as clientes_mes_0,
    COUNT(DISTINCT CASE WHEN mes_compra = mes_cohort + INTERVAL '1 month' THEN id_cliente_anonimo END) as clientes_mes_1,
    COUNT(DISTINCT CASE WHEN mes_compra = mes_cohort + INTERVAL '2 months' THEN id_cliente_anonimo END) as clientes_mes_2,
    ROUND(
        100.0 * COUNT(DISTINCT CASE WHEN mes_compra = mes_cohort + INTERVAL '1 month' THEN id_cliente_anonimo END)
        / NULLIF(COUNT(DISTINCT CASE WHEN mes_cohort = mes_compra THEN id_cliente_anonimo END), 0),
        2
    ) as retencao_mes_1_pct
FROM vendas_com_cohort
GROUP BY mes_cohort
ORDER BY mes_cohort;


-- 6.3 Moving Average (Média Móvel de 3 Meses)
SELECT 
    ano_mes,
    faturamento_mensal,
    ROUND(
        AVG(faturamento_mensal) OVER (
            ORDER BY ano_mes 
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ), 
        2
    ) as media_movel_3_meses
FROM (
    SELECT 
        ano_mes,
        SUM(valor_total_pedido) as faturamento_mensal
    FROM pedidos
    GROUP BY ano_mes
) AS vendas
ORDER BY ano_mes;


-- =========================================
-- FIM DAS ANÁLISES
-- =========================================

-- RESUMO PARA DOCUMENTAÇÃO:
-- Total de Queries: 19
-- Técnicas Demonstradas:
--   - Agregações (SUM, AVG, COUNT)
--   - Window Functions (RANK, LAG, AVG OVER)
--   - CTEs (Common Table Expressions)
--   - JOINs (INNER JOIN, LEFT JOIN)
--   - CASE Statements
--   - Análise de Cohort
--   - Moving Averages
--   - Segmentações