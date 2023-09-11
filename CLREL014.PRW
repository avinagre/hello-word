#include "TOTVS.ch"
#include "tbiconn.ch"
#include "topconn.ch"
#INCLUDE "FWMVCDEF.CH"
#include "fileio.ch"

/*/{Protheus.doc} CLREL014
  (long_description)
  @Rodrigo Romão
  @since 22/03/2021
  @version version
  /*/
Class CLREL014

	data dDataDe
	data dDataAte
	data nVendaBruta
	data nImpostos
	data nVendLiquida
	data nVendNProduto
	data nVendLiqNProduto
	data nMarqBruta
	data nTotCustoFinal

	Method New() Constructor
	Method execute()

	Method getVlrGrupos(cGrpAlimentos)

	Method getEstInicial()
	Method getCompras()
	Method getTraEmi()
	Method getTraRec()
	Method getDevolucao()
	Method getPromocao()
	method getEstFinal()
	method setVendaBruta()
	method setVNP() 					//Venda Nao produto
	method setVLNP() 					//Venda  liquida Nao produto
	method getHMBDetail()

	method getDtDe()
	method setDtDe()
	method getDtAte()
	method setDtAte()
EndClass

Method New() Class CLREL014
	::dDataDe   				:= ctod("")
	::dDataAte  				:= ctod("")
	::nVendaBruta				:= 0
	::nImpostos 				:= 0
	::nVendLiquida 			:= 0
	::nVendNProduto 		:= 0
	::nVendLiqNProduto	:= 0
	::nMarqBruta 				:= 0
	::nTotCustoFinal		:= 0
Return

/*/{Protheus.doc} Execute
  (long_description)
  @Rodrigo Romao
  @since 22/03/2021
  @version version
  @param param_name, param_type, param_descr
  @return return_var, return_type, return_description
  /*/
Method Execute(cDataDe, cDataAte) Class CLREL014

	local cGrpAlimentos		:= "0001"
	local cGrpEmbalagens	:= "0002"
	local cGrpHMB					:= "0013"
	local cGrpSLP					:= "0014"
	local cGrpFrete				:= "FRETE"

	local aRetAlimentos		:= {}
	local aRetEmbalagens	:= {}
	local aRetHMB					:= {}
	local aRetSLP					:= {}
	local aRetFretes			:= {}

	::setDtDe(cDataDe)
	::setDtAte(cDataAte)

	oReturn := JsonObject():new()
	oReturn['data_hora_geracao'] := Dtoc(dDataBase) + " " + Alltrim(Time())

	::setVendaBruta("VENDA_BRUTA")
	::nVendLiquida		:= ::nVendaBruta - ::nImpostos

	aRetAlimentos  := ::getVlrGrupos(cGrpAlimentos	,"Alimentos")
	aRetEmbalagens := ::getVlrGrupos(cGrpEmbalagens	,"Embalagens")
	aRetHMB 			 := ::getVlrGrupos(cGrpHMB				,"Brindes HMB")
	aRetSLP				 := ::getVlrGrupos(cGrpSLP				,"Brindes SLP")
	aRetFretes  	 := ::getVlrGrupos(cGrpFrete			,"Frete")

	oReturn['ALIMENTOS']	:= aRetAlimentos
	oReturn['EMBALAGENS']	:= aRetEmbalagens
	oReturn['HMB']				:= aRetHMB
	oReturn['SLP']				:= aRetSLP
	oReturn['FRETES'] 		:= aRetFretes

	::setVNP()
	::setVLNP()
	::nMarqBruta				:= Round((1 - (::nTotCustoFinal/::nVendLiquida)) * 100,2)

	oReturn['VENDA_BRUTA'] 								:= Alltrim(Transform(::nVendaBruta			,"@E 999,999,999.99"))
	oReturn['IMPOSTOS'] 									:= Alltrim(Transform(::nImpostos				,"@E 999,999,999.99"))
	oReturn['VENDA_LIQUIDA'] 							:= Alltrim(Transform(::nVendLiquida			,"@E 999,999,999.99"))
	oReturn['VENDA_NAO_PRODUTOS'] 				:= Alltrim(Transform(::nVendNProduto		,"@E 999,999,999.99"))
	oReturn['VENDA_LIQUIDA_NAO_PRODUTOS'] := Alltrim(Transform(::nVendLiqNProduto	,"@E 999,999,999.99"))
	oReturn['MARGEM_BRUTA'] 							:= Alltrim(Transform(::nMarqBruta				,"@E 999,999,999.99"))

	oReturn['BRINDES_HMB'] := ::getHMBDetail()
Return(oReturn)

/*/{Protheus.doc} getVlrAlimentos(cGrpAlimentos)
	(long_description)
	@author user
	@since 29/03/2021
	@version version
	@param param_name, param_type, param_descr
	@return return_var, return_type, return_description
	/*/
Method getVlrGrupos(cGrpAlimentos, cItem) Class CLREL014
	local oRet 				:= JsonObject():new()
	local nEstIni 		:= 0
	local nCompras		:= 0
	local nTranEmi		:= 0
	local nTranRec		:= 0
	local nDevolucao	:= 0
	local nPromocao		:= 0
	local nEstFinal		:= 0
	local nCustoFinal	:= 0

	nEstIni 		:= ::getEstInicial(cGrpAlimentos)
	nCompras		:= ::getCompras(cGrpAlimentos)
	nTranEmi		:= ::getTraEmi(cGrpAlimentos)
	nTranRec		:= ::getTraRec(cGrpAlimentos)
	nDevolucao	:= ::getDevolucao(cGrpAlimentos)
	nPromocao		:= ::getPromocao(cGrpAlimentos)
	nEstFinal		:= ::getEstFinal(cGrpAlimentos)

	nCustoFinal	:= (nEstIni + nCompras - nTranEmi + nTranRec - nDevolucao - nPromocao - nEstFinal)

	oRet["ITENS"]						 					:= cItem
	oRet["ESTOQUE_INICIAL"] 					:= Alltrim(Transform(nEstIni,"@E 999,999,999.99"))
	oRet["COMPRAS"] 									:= Alltrim(Transform(nCompras,"@E 999,999,999.99"))
	oRet["TRANSFERENCIAS_EMITIDAS"] 	:= Alltrim(Transform(nTranEmi,"@E 999,999,999.99"))
	oRet["TRANSFERENCIAS_RECEBIDAS"]	:= Alltrim(Transform(nTranRec,"@E 999,999,999.99"))
	oRet["DEVOLUCOES"]								:= Alltrim(Transform(nDevolucao,"@E 999,999,999.99"))
	oRet["PROMOCAO"]									:= Alltrim(Transform(nPromocao,"@E 999,999,999.99"))
	oRet["ESTOQUE_FINAL"]							:= Alltrim(Transform(nEstFinal,"@E 999,999,999.99"))
	oRet["CUSTO_FINAL"]								:= Alltrim(Transform(nCustoFinal,"@E 999,999,999.99"))
	oRet["PERCENTAGEM_VL"]						:= Alltrim(Transform((nCustoFinal*100)/::nVendLiquida,"@E 99.99"))

	::nTotCustoFinal += nCustoFinal

Return oRet

/*/{Protheus.doc} setVNP
  	Venda Nao produto
  @Rodrigo Romao
  @since 22/03/2021
  @version version
  @param param_name, param_type, param_descr
  @return return_var, return_type, return_description
  /*/
method setVNP() class CLREL014
	local cAlias    := ""
	local dDataDe   := ::getDtDe()
	local dDataAte  := ::getDtAte()
	local cGrpHMB		:= "0013"
	local cTipo			:= 'S'

	::nVendNProduto := 0

	cALias := GetNextAlias()

	cQuery := " SELECT  SUM(D2_QUANT) AS TOTAL, " + CRLF
	cQuery += " 				SUM(SD2.D2_VALIPI+SD2.D2_VALICM+SD2.D2_VALIPI+SD2.D2_VALIMP5+SD2.D2_VALIMP6) AS VLR_IMPOSTOS " + CRLF
	cQuery += " FROM " + RetSqlTab("SB1") + " " + CRLF
	cQuery += " 	INNER JOIN " + RetSqlTab("SD2") + " " + CRLF
	cQuery += " 	 ON  SD2.D2_COD = SB1.B1_COD " + CRLF
	cQuery += " 	 AND SD2.D2_FILIAL = '"+xFilial("SD2")+"' " + CRLF
	cQuery += " 	 AND SD2.D_E_L_E_T_ <> '*'" + CRLF
	// cQuery += " 	INNER JOIN " + RetSqlTab("SD3") + " " + CRLF
	// cQuery += " 	 ON SD3.D3_COD = SB1.B1_COD " + CRLF
	// cQuery += " 	 AND SD3.D3_FILIAL = '"+xFilial("SD3")+"' " + CRLF
	// cQuery += " 	 AND SD3.D_E_L_E_T_ <> '*'" + CRLF
	cQuery += " WHERE 1=1" + CRLF
	cQuery += " AND SB1.D_E_L_E_T_ <> '*'" + CRLF
	cQuery += " AND SB1.B1_FILIAL = '"+xFilial("SB1")+"'" + CRLF
	cQuery += " AND SB1.B1_GRUPO = '"+Alltrim(cGrpHMB)+"'" + CRLF
	//cQuery += " AND SD2.D2_COD = '" + cCodProd + "'" + CRLF
	cQuery += " AND SD2.D2_EMISSAO BETWEEN '"+dtos(dDataDe)+"' AND '"+dtos(dDataAte)+"'" + CRLF
	// cQuery += " AND SD3.D3_CF in ('RE1')" + CRLF
	cQuery += " AND SB1.B1_ZRENSTA = '" + cTipo + "'"

	cQuery := ChangeQuery(cQuery)
	DbUseArea(.T.,"TOPCONN",TCGENQRY(,,cQuery),cALias,.T.,.T.)

	If (cALias)->(!Eof())
		::nVendNProduto := (cAlias)->TOTAL - (cAlias)->VLR_IMPOSTOS
	endif

	(cALias)->(DBCloseArea())

return

/*/{Protheus.doc} setVLNP
  Venda  liquida Nao produto
  @Rodrigo Romao
  @since 22/03/2021
  @version version
  @param param_name, param_type, param_descr
  @return return_var, return_type, return_description
  /*/
method setVLNP() class CLREL014
	::nVendLiqNProduto := ::nVendLiquida - ::nVendNProduto
return

/*/{Protheus.doc} getVlrReal
  (long_description)
  @Rodrigo Romao
  @since 22/03/2021
  @version version
  @param param_name, param_type, param_descr
  @return return_var, return_type, return_description
  /*/
Method setVendaBruta() class CLREL014
	local cAlias    := ""
	local dDataDe   := ::getDtDe()
	local dDataAte  := ::getDtAte()

	cALias := GetNextAlias()

	cQuery := " SELECT  " + CRLF
	cQuery += "   sum(SF2.F2_VALBRUT) as VALBRUT, " + CRLF
	cQuery += "   sum(SF2.F2_VALIPI+SF2.F2_VALICM+SF2.F2_VALCOFI+SF2.F2_VALIPI+SF2.F2_VALCSLL+SF2.F2_VALIMP5+SF2.F2_VALIMP6) AS VLR_IMPOSTOS " + CRLF
	cQuery += " FROM " + RetSqlTab("SF2") + " " + CRLF
	cQuery += " WHERE SF2.D_E_L_E_T_ <> '*' " + CRLF
	cQuery += "  AND SF2.F2_FILIAL = '" + xFilial("SF2") + "' " + CRLF
	cQuery += "  AND SF2.F2_EMISSAO between '" + dtos(dDataDe) + "' and '" + dtos(dDataAte) + "' " + CRLF

	cQuery := ChangeQuery(cQuery)
	DbUseArea(.T.,"TOPCONN",TCGENQRY(,,cQuery),cALias,.T.,.T.)

	If (cALias)->(!Eof())
		::nVendaBruta := (cAlias)->VALBRUT
		::nImpostos   := (cAlias)->VLR_IMPOSTOS
	endif

	(cALias)->(DBCloseArea())

Return

/*/{Protheus.doc} getEstInicial
	(long_description)
	@author user
	@since 29/03/2021
	@version version
	@param param_name, param_type, param_descr
	@return return_var, return_type, return_description
	/*/
Method getEstInicial(cGrupo) Class CLREL014
	local nRet 			:= 0
	local cAlias    := ""
	local dDataDe   := ::getDtDe()
	local dMesAnt  	:= ctod("")

	dPrimieraData := FirstDate(dDataDe)
	dMesAnt := dPrimieraData-1

	cALias := GetNextAlias()

	cQuery := " SELECT TOP 1 SB9.B9_QINI AS TOTAL " + CRLF
	cQuery += " FROM " + RetSqlTab("SB1") + " " + CRLF
	cQuery += " 	INNER JOIN " + RetSqlTab("SB9") + " " + CRLF
	cQuery += " 	 ON SB9.B9_COD = SB1.B1_COD " + CRLF
	cQuery += " 	 AND SB9.B9_FILIAL = '"+xFilial("SB9")+"' " + CRLF
	cQuery += " 	 AND SB9.D_E_L_E_T_ <> '*'" + CRLF
	cQuery += " WHERE 1=1" + CRLF
	cQuery += " AND SB1.D_E_L_E_T_ <> '*'" + CRLF
	CQUERY += " AND SB1.B1_FILIAL = '" + xFilial("SB1") + "'" + CRLF
	CQUERY += " AND SB1.B1_GRUPO = '" + Alltrim(cGrupo) + "'" + CRLF
	cQuery += " AND SB9.B9_DATA = '" + dtos(dMesAnt) + "'" + CRLF
	cQuery += " AND SB1.B1_ZRENSTA = 'S'"

	cQuery := ChangeQuery(cQuery)
	DbUseArea(.T.,"TOPCONN",TCGENQRY(,,cQuery),cALias,.T.,.T.)

	If (cALias)->(!Eof())
		nRet := (cAlias)->TOTAL
	endif

	(cALias)->(DBCloseArea())

Return(nRet)

/*/{Protheus.doc} getCompras
	(long_description)
	@author user
	@since 29/03/2021
	@version version
	@param param_name, param_type, param_descr
	@return return_var, return_type, return_description
	/*/
Method getCompras(cGrpAlimentos) class CLREL014
	local nRet 			:= 0
	local cAlias    := ""
	local dDataDe   := ::getDtDe()
	local dDataAte  := ::getDtAte()

	cALias := GetNextAlias()

	cQuery := " SELECT SUM(D1_TOTAL) AS TOTAL " + CRLF
	cQuery += " FROM " + RetSqlTab("SB1") + " " + CRLF
	cQuery += " 	INNER JOIN " + RetSqlTab("SD1") + " ON SD1.D1_COD = SB1.B1_COD AND SD1.D1_FILIAL = '"+xFilial("SD1")+"' AND SD1.D_E_L_E_T_ <> '*'" + CRLF
	cQuery += " WHERE 1=1" + CRLF
	cQuery += " AND SB1.D_E_L_E_T_ <> '*'" + CRLF
	CQUERY += " AND SB1.B1_FILIAL = '"+xFilial("SB1")+"'" + CRLF
	CQUERY += " AND SB1.B1_GRUPO = '"+Alltrim(cGrpAlimentos)+"'" + CRLF
	cQuery += " AND SD1.D1_EMISSAO BETWEEN '"+dtos(dDataDe)+"' AND '"+dtos(dDataAte)+"'" + CRLF
	cQuery += " AND SB1.B1_ZRENSTA = 'S'"

	cQuery := ChangeQuery(cQuery)
	DbUseArea(.T.,"TOPCONN",TCGENQRY(,,cQuery),cALias,.T.,.T.)

	If (cALias)->(!Eof())
		nRet := (cAlias)->TOTAL
	endif

	(cALias)->(DBCloseArea())

Return(nRet)

/*/{Protheus.doc} getTraEmi
	(long_description)
	@author user
	@since 29/03/2021
	@version version
	@param param_name, param_type, param_descr
	@return return_var, return_type, return_description
	/*/
Method getTraEmi(cGrupo) class CLREL014
	local nRet 			:= 0
	local cAlias    := ""
	local dDataDe   := ::getDtDe()
	local dDataAte  := ::getDtAte()

	cALias := GetNextAlias()

	cQuery := " SELECT SUM(D3_QUANT) AS TOTAL " + CRLF
	cQuery += " FROM " + RetSqlTab("SB1") + " " + CRLF
	cQuery += " 	LEFT JOIN " + RetSqlTab("SD3") + " ON SD3.D3_COD = SB1.B1_COD AND SD3.D3_FILIAL = '"+xFilial("SD3")+"' AND SD3.D_E_L_E_T_ <> '*'" + CRLF
	cQuery += " WHERE 1=1" + CRLF
	cQuery += " AND SB1.D_E_L_E_T_ <> '*'" + CRLF
	CQUERY += " AND SB1.B1_FILIAL = '"+xFilial("SB1")+"'" + CRLF
	CQUERY += " AND SB1.B1_GRUPO = '"+Alltrim(cGrupo)+"'" + CRLF
	cQuery += " AND SD3.D3_EMISSAO BETWEEN '"+dtos(dDataDe)+"' AND '"+dtos(dDataAte)+"'" + CRLF
	cQuery += " AND SD3.D3_CF in ('RE3','RE4')" + CRLF
	cQuery += " AND SB1.B1_ZRENSTA = 'S'"

	cQuery := ChangeQuery(cQuery)
	DbUseArea(.T.,"TOPCONN",TCGENQRY(,,cQuery),cALias,.T.,.T.)

	If (cALias)->(!Eof())
		nRet := (cAlias)->TOTAL
	endif

	(cALias)->(DBCloseArea())

Return(nRet)

/*/{Protheus.doc} getTraRec
	(long_description)
	@author user
	@since 29/03/2021
	@version version
	@param param_name, param_type, param_descr
	@return return_var, return_type, return_description
	/*/
Method getTraRec(cGrupo) class CLREL014
	local nRet 			:= 0
	local cAlias    := ""
	local dDataDe   := ::getDtDe()
	local dDataAte  := ::getDtAte()

	cALias := GetNextAlias()

	cQuery := " SELECT SUM(D3_QUANT) AS TOTAL " + CRLF
	cQuery += " FROM " + RetSqlTab("SB1") + " " + CRLF
	cQuery += " 	LEFT JOIN " + RetSqlTab("SD3") + " ON SD3.D3_COD = SB1.B1_COD AND SD3.D3_FILIAL = '"+xFilial("SD3")+"' AND SD3.D_E_L_E_T_ <> '*'" + CRLF
	cQuery += " WHERE 1=1" + CRLF
	cQuery += " AND SB1.D_E_L_E_T_ <> '*'" + CRLF
	CQUERY += " AND SB1.B1_FILIAL = '"+xFilial("SB1")+"'" + CRLF
	CQUERY += " AND SB1.B1_GRUPO = '"+Alltrim(cGrupo)+"'" + CRLF
	cQuery += " AND SD3.D3_EMISSAO BETWEEN '"+dtos(dDataDe)+"' AND '"+dtos(dDataAte)+"'" + CRLF
	cQuery += " AND SD3.D3_CF in ('DE3','DE4')" + CRLF
	cQuery += " AND SB1.B1_ZRENSTA = 'S'"

	cQuery := ChangeQuery(cQuery)
	DbUseArea(.T.,"TOPCONN",TCGENQRY(,,cQuery),cALias,.T.,.T.)

	If (cALias)->(!Eof())
		nRet := (cAlias)->TOTAL
	endif

	(cALias)->(DBCloseArea())
Return(nRet)

/*/{Protheus.doc} getDevolucao
	(long_description)
	@author user
	@since 29/03/2021
	@version version
	@param param_name, param_type, param_descr
	@return return_var, return_type, return_description
	/*/
Method getDevolucao(cGrupo) class CLREL014
	local nRet 			:= 0
	local cAlias    := ""
	local dDataDe   := ::getDtDe()
	local dDataAte  := ::getDtAte()

	cALias := GetNextAlias()

	cQuery := " SELECT SUM(D3_QUANT) AS TOTAL " + CRLF
	cQuery += " FROM " + RetSqlTab("SB1") + " " + CRLF
	cQuery += " 	LEFT JOIN " + RetSqlTab("SD3") + " ON SD3.D3_COD = SB1.B1_COD AND SD3.D3_FILIAL = '"+xFilial("SD3")+"' AND SD3.D_E_L_E_T_ <> '*'" + CRLF
	cQuery += " WHERE 1=1" + CRLF
	cQuery += " AND SB1.D_E_L_E_T_ <> '*'" + CRLF
	CQUERY += " AND SB1.B1_FILIAL = '"+xFilial("SB1")+"'" + CRLF
	CQUERY += " AND SB1.B1_GRUPO = '"+Alltrim(cGrupo)+"'" + CRLF
	cQuery += " AND SD3.D3_EMISSAO BETWEEN '"+dtos(dDataDe)+"' AND '"+dtos(dDataAte)+"'" + CRLF
	cQuery += " AND SD3.D3_CF in ('DE0','DE1','DE2')" + CRLF
	cQuery += " AND SB1.B1_ZRENSTA = 'S'"

	cQuery := ChangeQuery(cQuery)
	DbUseArea(.T.,"TOPCONN",TCGENQRY(,,cQuery),cALias,.T.,.T.)

	If (cALias)->(!Eof())
		nRet := (cAlias)->TOTAL
	endif

	(cALias)->(DBCloseArea())
Return(nRet)

/*/{Protheus.doc} getPromocao
	(long_description)
	@author user
	@since 29/03/2021
	@version version
	@param param_name, param_type, param_descr
	@return return_var, return_type, return_description
	/*/
Method getPromocao(cGrupo) class CLREL014
	local nRet 			:= 0
	local cAlias    := ""
	local dDataDe   := ::getDtDe()
	local dDataAte  := ::getDtAte()
	local cTipo			:= 'S'

	cALias := GetNextAlias()

	cQuery := " SELECT SUM(ZZG_QUANT) AS TOTAL " + CRLF
	cQuery += " FROM " + RetSqlTab("SB1") + " " + CRLF
	cQuery += " 	INNER JOIN " + RetSqlTab("ZZG") + " " + CRLF
	cQuery += " 	 ON ZZG.ZZG_PRODUT = SB1.B1_COD " + CRLF
	cQuery += " 	 AND ZZG.ZZG_FILIAL = '"+xFilial("ZZG")+"' " + CRLF
	cQuery += " 	 AND ZZG.D_E_L_E_T_ <> '*'" + CRLF
	cQuery += " WHERE 1=1" + CRLF
	cQuery += " AND SB1.D_E_L_E_T_ <> '*'" + CRLF
	CQUERY += " AND SB1.B1_FILIAL = '"+xFilial("SB1")+"'" + CRLF
	CQUERY += " AND SB1.B1_GRUPO = '"+Alltrim(cGrupo)+"'" + CRLF
	cQuery += " AND ZZG.ZZG_DATA BETWEEN '"+dtos(dDataDe)+"' AND '"+dtos(dDataAte)+"'" + CRLF
	//cQuery += " AND ZZG.ZZG_PRODUT = '" + cCodProd + "'" + CRLF
	cQuery += " AND ZZG.ZZG_ROTINA = 'Promo'" + CRLF
	cQuery += " AND ZZG.ZZG_TIPO = 'R'" + CRLF
	cQuery += " AND SB1.B1_ZRENSTA = '" + cTipo + "'"

	cQuery := ChangeQuery(cQuery)
	DbUseArea(.T.,"TOPCONN",TCGENQRY(,,cQuery),cALias,.T.,.T.)

	If (cALias)->(!Eof())
		nRet := (cAlias)->TOTAL
	endif

	(cALias)->(DBCloseArea())

Return(nRet)

/*/{Protheus.doc} getEstFinal
	(long_description)
	@author user
	@since 29/03/2021
	@version version
	@param param_name, param_type, param_descr
	@return return_var, return_type, return_description
	/*/
method getEstFinal(cGrupo) class CLREL014
	local nRet 			:= 0
	local cAlias    := ""
	local dDataDe   := ::getDtDe()
	local dDataAte  := ::getDtAte()

	cALias := GetNextAlias()

	cQuery := " SELECT SUM(B2_QATU) AS TOTAL " + CRLF
	cQuery += " FROM " + RetSqlTab("SB1") + " " + CRLF
	cQuery += " 	LEFT JOIN " + RetSqlTab("SB2") + " " + CRLF
	cQuery += " 		ON  SB2.B2_COD = SB1.B1_COD " + CRLF
	cQuery += " 		AND SB2.B2_LOCAL = SB1.B1_LOCPAD " + CRLF
	cQuery += " 		AND SB2.B2_FILIAL = '"+xFilial("SB2")+"' " + CRLF
	cQuery += " 		AND SB2.D_E_L_E_T_ <> '*'" + CRLF
	cQuery += " WHERE 1=1" + CRLF
	cQuery += " AND SB1.D_E_L_E_T_ <> '*'" + CRLF
	CQUERY += " AND SB1.B1_FILIAL = '"+xFilial("SB1")+"'" + CRLF
	CQUERY += " AND SB1.B1_GRUPO = '"+Alltrim(cGrupo)+"'" + CRLF
	cQuery += " AND SB1.B1_ZRENSTA = 'S'"

	cQuery := ChangeQuery(cQuery)
	DbUseArea(.T.,"TOPCONN",TCGENQRY(,,cQuery),cALias,.T.,.T.)

	If (cALias)->(!Eof())
		nRet := (cAlias)->TOTAL
	endif

	(cALias)->(DBCloseArea())

Return(nRet)

method getHMBDetail() Class CLREL014
	local oRet 		:= JsonObject():new()
	local cAlias	:= ""
	local cQuery	:= ""
	local dDataDe   := ::getDtDe()
	local dDataAte  := ::getDtAte()

	//cALias := GetNextAlias()

Return(oRet)

/* --------- gets e sets ---------- */
method getDtDe() class CLREL014
	local dRet := ::dDataDe
return(dRet)

method setDtDe(cParam) class CLREL014
	local aData := StrToKarr(cParam,"-")
	local cTemp := ctod(aData[3]+"/"+aData[2]+"/"+aData[1])
	::dDataDe := cTemp
return

method getDtAte() class CLREL014
	local dRet := ::dDataAte
return(dRet)

method setDtAte(cParam) class CLREL014
	local aData := StrToKarr(cParam,"-")
	local cTemp := ctod(aData[3]+"/"+aData[2]+"/"+aData[1])
	::dDataAte := cTemp
return
