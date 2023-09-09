#INCLUDE "TOTVS.CH"
#INCLUDE "RESTFUL.CH"
#include "topconn.ch"

WSRESTFUL WCRES001 DESCRIPTION "Inventario Leicos" FORMAT APPLICATION_JSON

	WSDATA page AS INTEGER OPTIONAL
	WSDATA pageSize AS INTEGER OPTIONAL
	WSDATA searchKey AS STRING OPTIONAL

	WSMETHOD GET DESCRIPTION "get dados inventario" WSSYNTAX "/ || /{tipo}/{data}"
	WSMETHOD POST DESCRIPTION "Gravacao dos dados de inventario" WSSYNTAX "/" PATH "/"
	WSMETHOD POST APROVAR DESCRIPTION "Aprovar inventario" WSSYNTAX "/aprovar" PATH "/aprovar"

END WSRESTFUL

WSMETHOD GET WSRECEIVE searchKey, page, pageSize WSREST WCRES001
  Local cALias    := GetNextAlias()
  Local oJsonInv  := JsonObject():New()
  Local aListInv  := {}
  Local nAux      := 0
  local cQuery    := ""
  local aParam    := NIL
  local cData     := ""

  ::SetContentType("application/json")

  If Len(::aURLParms) > 0
    aParam := ::aURLParms

    cTipo := aParam[1]
    cData := aParam[2]

  else
    FWLogMsg("INFO",,"ZCONOUT",,,,"nao tem parametros",,,)
  endif

  lCheckInvent := checkInventario(cData, "")

  if !lCheckInvent
    SetRestFault(404,EncodeUTF8('Não é permitido mais de um inventario na mesma data.'))
  Return .f.
  endif

  // cQuery := "SELECT SB7.B7_COD, SB1.B1_DESC, SB1.B1_UM, SB7.B7_LOCAL, SB7.B7_QUANT, SB7.B7_DATA, SB7.B7_STATUS " + CRLF
  // cQuery += " FROM " + RetSqlTab("SB7") + " " + CRLF
  // cQuery += "   INNER JOIN " + RetSqlTab("SB1") + " ON SB1.B1_COD = SB7.B7_COD AND SB1.D_E_L_E_T_ = '' AND SB1.B1_FILIAL = '" + xFilial("SB1") + "'"
  // cQuery += " WHERE SB7.D_E_L_E_T_ = ''" + CRLF
  // cQuery += "   AND SB7.B7_FILIAL = '" + xFilial("SB7") + "'"
  // cQuery += "   AND SB7.B7_STATUS = '1'"

  // if !Empty(cData)
  // 	cQuery += "   AND SB7.B7_DATA   = '" + cData + "'"
  // endif

  cQuery := " SELECT SB1.B1_COD, SB1.B1_DESC, SB1.B1_LOCPAD, SB1.B1_UM, SB1.B1_XDIARIO, SB1.B1_XSEMANA, " + CRLF
  cQuery += " SB1.B1_XQUINZE, SB1.B1_XMENSAL, SB1.B1_ATIVO, X5_DESCRI, SB1.B1_SEGUM, SB1.B1_CONV, SB1.B1_TIPCONV, " + CRLF
  cQuery += " SB7.B7_DOC, SB7.B7_LOCAL, SB7.B7_QUANT, SB7.B7_DATA, SB7.B7_STATUS, SB1.B1_XTERUM, SB1.B1_XCONV " + CRLF

  cQuery += " FROM " + RetSqlName("SB1") + " SB1 " + CRLF
  
  cQuery += " LEFT JOIN " + RetSqlName("SX5") + " X5 ON X5_TABELA = 'ZA' AND X5_CHAVE = B1_XFAMILI AND X5.D_E_L_E_T_ = '' " + CRLF
  cQuery += " LEFT JOIN " + RetSqlTab("SB7") + " ON SB1.B1_COD = SB7.B7_COD AND SB7.B7_STATUS = '1' AND SB7.B7_DATA = '" + cData + "' AND SB7.D_E_L_E_T_ <> '*' AND SB7.B7_FILIAL = '" + xFilial("SB7") + "'"

  cQuery += " WHERE SB1.D_E_L_E_T_ = ''" + CRLF
  cQuery += " AND SB1.B1_FILIAL = '" + xFilial("SB1") + "'"

  if Alltrim(Upper(cTipo)) $ "INVENTARIO|DIARIO|SEMANAL|QUINZENAL|MENSAL"
    cQuery += " AND SB1.B1_XFAMILI IN ('000006','000007','000008','000009') "
  endif

  if Alltrim(Upper(cTipo)) == "PERDAS_COMPLETO"
    cQuery += " AND SB1.B1_GRUPO IN ('0010')"
    cQuery += " AND SB1.B1_XFAMILI <> '' "
    cQuery += " AND SB1.B1_XMASTER = 'S' "
  endif

  if Alltrim(Upper(cTipo)) == "PERDAS_INCOMPLETO"
    cQuery += " AND SB1.B1_XFAMILI IN ('000007','000008','000009') "
  endif

  if Alltrim(Upper(cTipo)) == "BREAKS"
    cQuery += "   AND SB1.B1_GRUPO IN ('0006','0010')"
    cQuery += " AND SB1.B1_XMASTER = 'S' "
  endif

  if Alltrim(Upper(cTipo)) == "PROMOCAO_COMPLETOS"
    cQuery += "   AND SB1.B1_GRUPO IN ('0013','0014')"
  endif

  if Alltrim(Upper(cData)) != "ALL"
    //cQuery += " AND SB1.B1_COD NOT IN (SELECT SB7.B7_COD FROM " + RetSqlName("SB7") + "  WHERE SB7.D_E_L_E_T_ = '' AND SB7.B7_DATA = '" + cData + "' AND SB7.B7_STATUS = '1') "
  endif

  if alltrim(cTipo) == "DIARIO"
    cQuery += "   AND SB1.B1_XDIARIO   = 'S'"
  endif

  if alltrim(cTipo) == "SEMANAL"
    cQuery += "   AND SB1.B1_XSEMANA   = 'S'"
  endif

  if alltrim(cTipo) == "QUINZENAL"
    cQuery += "   AND SB1.B1_XQUINZE   = 'S'"
  endif

  if alltrim(cTipo) == "MENSAL"
    cQuery += "   AND SB1.B1_XMENSAL   = 'S'"
  endif

  if Alltrim(Upper(cTipo)) == "PERDAS_COMPLETO" .OR. Alltrim(Upper(cTipo)) == "BREAKS" //.OR.  Alltrim(Upper(cTipo)) $ "INVENTARIO"
    cQuery += " ORDER BY SB1.B1_XFAMILI, B1_DESC "
  ENDIF

  if Alltrim(Upper(cTipo)) $ "INVENTARIO" .OR. Alltrim(Upper(cTipo)) == "PERDAS_INCOMPLETO"
    cQuery += " ORDER BY SB1.B1_XFAMILI DESC "
  ENDIF

  FWLogMsg("INFO",,"ZCONOUT",,,,cQuery,,,)

  cQuery := ChangeQuery(cQuery)
  DbUseArea(.T.,"TOPCONN",TCGENQRY(,,cQuery),cALias,.T.,.T.)

  If (cALias)->(!Eof())

    While (cALias)->(!Eof())

      nAux++
      aAdd( aListInv , JsonObject():New() )
      aListInv[nAux]['B1_COD']      := Alltrim((cALias)->B1_COD)
      aListInv[nAux]['B1_DESC']     := Alltrim((cALias)->B1_DESC)
      aListInv[nAux]['B1_LOCPAD']   := Alltrim((cALias)->B1_LOCPAD)
      aListInv[nAux]['B1_UM']       := Alltrim((cALias)->B1_UM)
      aListInv[nAux]['B1_XDIARIO']  := Alltrim((cALias)->B1_XDIARIO)
      aListInv[nAux]['B1_XSEMANA']  := Alltrim((cALias)->B1_XSEMANA)
      aListInv[nAux]['B1_XQUINZE']  := Alltrim((cALias)->B1_XQUINZE)
      aListInv[nAux]['B1_XMENSAL']  := Alltrim((cALias)->B1_XMENSAL)
      aListInv[nAux]['B1_ATIVO']    := Alltrim((cALias)->B1_ATIVO)
      aListInv[nAux]['X5_DESCRI']   := Alltrim((cALias)->X5_DESCRI)
      aListInv[nAux]['B1_SEGUM']    := Alltrim((cALias)->B1_SEGUM)
      aListInv[nAux]['B1_CONV']     := (cALias)->B1_CONV
      aListInv[nAux]['B1_TIPCONV']  := Alltrim((cALias)->B1_TIPCONV)
      aListInv[nAux]['B7_DOC']      := Alltrim((cALias)->B7_DOC)
      aListInv[nAux]['B7_LOCAL']    := Alltrim((cALias)->B7_LOCAL)
      aListInv[nAux]['B7_QUANT']    := (cALias)->B7_QUANT
      aListInv[nAux]['B7_DATA']     := Alltrim((cALias)->B7_DATA)
	  aListInv[nAux]['B1_XTERUM']   := Alltrim((cALias)->B1_XTERUM)
	  aListInv[nAux]['B1_XCONV']    := (cALias)->B1_XCONV

      (cALias)->( DBSkip() )
    End
  endif
  (cALias)->(DBCloseArea())

  oJsonInv['inventario'] := aListInv
  cJsonInv := FwJsonSerialize( oJsonInv )

  FreeObj(oJsonInv)

  Self:SetResponse(cJsonInv) //-- Seta resposta

Return .T.

WSMETHOD POST WSSERVICE WCRES001
	Local lPost     := .T.
	local oJson     := nil
	local aListInv  := {}
	local nAux      := 0
	local i         := 0
	Local oJsonInv  := JsonObject():New()

	cJson := ::GetContent()

	Self:SetContentType("application/json")

	oJson := JsonObject():New()

	//Efetuar o parser do JSON
	cError := oJSON:fromJSON(cJson)

	//Se vazio, significa que o parser ocorreu sem erros
	if Empty(cError)

		oItems  := oJson:GetJsonObject('itens')

		FWLogMsg("INFO",,"ZCONOUT",,,,"####################",,,)
		FWLogMsg("INFO",,"ZCONOUT",,,,cEmpAnt,,,)
		FWLogMsg("INFO",,"ZCONOUT",,,,cFilAnt,,,)
		FWLogMsg("INFO",,"ZCONOUT",,,,"####################",,,)

		for i := 1 to Len(oItems)
			cCodigo     := Padr(oItems[i]:GetJsonObject('codigo'),TamSX3("B1_COD")[1])
			cDescricao  := oItems[i]:GetJsonObject('descricao')
			cLocal      := oItems[i]:GetJsonObject('local')
			nQuant      := IIF(VALTYPE(oItems[i]:GetJsonObject('quantidade'))=="C",Val(oItems[i]:GetJsonObject('quantidade')),oItems[i]:GetJsonObject('quantidade'))	
			cUnidade    := oItems[i]:GetJsonObject('unidade')
			dData       := sToD(oItems[i]:GetJsonObject('dataInventario'))
			cdata       := oItems[i]:GetJsonObject('dataInventario')

			aRet := LCGRVARQ(cCodigo,nQuant,dData,cLocal,cdata)

			nAux++
			aAdd( aListInv , JsonObject():New() )
			aListInv[nAux]['CODIGO']    := aRet[2]
			aListInv[nAux]['DESCRICAO'] := aRet[3]
		next
	endif

	oJsonInv['inventario'] := aListInv
	cJsonInv := FwJsonSerialize( oJsonInv )

	::SetResponse(cJsonInv)

Return lPost


/**
 * Rotina para realizar a aprovacao do inventário
 */
WSMETHOD POST APROVAR WSSERVICE WCRES001
	Local lPost     		:= .T.
	local oJson     		:= nil
	Local oJsonInv  		:= JsonObject():New()
	local lAprovar			:= .F.
	local cAprovar			:= ""
	private lMsErroAuto := .f.

	cJson := ::GetContent()

	Self:SetContentType("application/json")

	oJson := JsonObject():New()

	//Efetuar o parser do JSON
	cError := oJSON:fromJSON(cJson)

	//Se vazio, significa que o parser ocorreu sem erros
	if Empty(cError)
		cCodInventario  := oJson:GetJsonObject('CODIGO_INVENTARIO')
		FWLogMsg("INFO",,"ZCONOUT",,,,"codigo inventario => "+ cCodInventario,,,)

		SB7->(DbSetOrder(3))
		SB7->(DbSeek(xFilial("SB7") + Alltrim(cCodInventario)))

		MSExecAuto({|x,y,z| mata340(x,y,z)}, .T., cCodInventario, .F.)

		If !lMsErroAuto

			lIsCheckInvet := checkInventario("", Alltrim(cCodInventario))
			IF lIsCheckInvet
				lAprovar := .F.
				cAprovar := "Erro no processamento de acerto de inventário! => " + cCodInventario + CRLF
			else
				FWLogMsg("INFO",,"ZCONOUT",,,,"Processado com Sucesso! Documento: "+cCodInventario,,,)
				lAprovar := .T.
				cAprovar := "Processado com Sucesso! Documento: "+cCodInventario
			endif

		Else
			// ConOut("Erro no processamento de acerto de inventário!")
			cError := MostraErro("/dirdoc", "error.log") // ARMAZENA A MENSAGEM DE ERRO
			FWLogMsg("INFO",,"ZCONOUT",,,,cError,,,)
			lAprovar := .F.
			cAprovar := "Erro no processamento de acerto de inventário! => " + cCodInventario + CRLF
			cAprovar += cError
		EndIf

	endif

	oJsonInv['texto'] := Alltrim(cAprovar)
	oJsonInv['retorno'] := lAprovar

	cJsonInv := FwJsonSerialize( oJsonInv )

	::SetResponse(cJsonInv)

Return lPost

/**
 * Rotina para realizar a geracao do inventario no Protheus
 */
Static Function LCGRVARQ(cCodigo,nQuant,dData,cLocal,cdata)
	local aRet          := {.T.,"","",""}
	local nOperacao     := 0
	local lExecAuto     := .T.
	Private lMsErroAuto := .F.

	// sleep(3000)

	SB7->(DbSetOrder(1))
	If SB7->(DbSeek(xFilial("SB7")+cdata+cCodigo))
		nOperacao := 4

		if nQuant == SB7->B7_QUANT
			lExecAuto := .F.
		endif

	else
		nOperacao := 3
	endif

	if lExecAuto
		If SB1->(DbSeek(xFilial("SB1")+cCodigo))

			if nOperacao == 4

				aSB7 :=  {{"B7_COD"      , SB7->B7_COD                              ,Nil},;
					{"B7_QUANT"    , nQuant                                   ,Nil},;
					{"B7_DATA"     , SB7->B7_DATA                             ,Nil},;
					{"B7_LOCAL"    , SB7->B7_LOCAL                            ,Nil},;
					{"INDEX"       , 1                                        ,NIL}}

			elseif nOperacao == 3

				aSB7 :=  {{"B7_FILIAL"   , xFilial("SB7")                           ,Nil},;
					{"B7_COD"      , cCodigo                                  ,Nil},;
					{"B7_DOC"      , "INV"+ALLTRIM(GRAVADATA(dData,.F.,1))    ,Nil},;
					{"B7_QUANT"    , nQuant                                   ,Nil},;
					{"B7_DATA"     , dData                                    ,Nil},;
					{"B7_LOCAL"    , cLocal                                   ,Nil},;
					{"B7_ORIGEM"   , "LCEST01"                                ,Nil}}
			endif

			MsExecAuto({|x,y,z| mata270(x,y,z)},aSB7,.T.,nOperacao)

			If !lMsErroAuto
				if nOperacao == 3
					cTexto := "Inventario incluido com sucesso"
				elseif nOperacao == 4
					cTexto := "Inventario alterado com sucesso"
				endif
				aRet := {.T.,cCodigo,cTexto}
			Else
				cError := MostraErro("/dirdoc", "error.log") // ARMAZENA A MENSAGEM DE ERRO
				FWLogMsg("INFO",,"ZCONOUT",,,,cError,,,)
				aRet := {.F.,cCodigo,cError}
			EndIf
		EndIf
	else
		aRet := {.T.,cCodigo,"Não foi necessário realizar o inventario, pois a quantidade estava a mesma no protheus."}
	endif

Return (aRet)

/**
 * Rotina para realizar a geracao do inventario no Protheus
 */
Static Function checkInventario(cData, cCodInv)
	Local cALias  	:= GetNextAlias()
	local cQuery  	:= ""
	local lRet    	:= .T.	

	cQuery := "SELECT SB7.B7_COD, SB1.B1_DESC, SB1.B1_UM, SB7.B7_LOCAL, SB7.B7_QUANT, SB7.B7_DATA " + CRLF
	cQuery += " FROM " + RetSqlTab("SB7") + " " + CRLF
	cQuery += "   INNER JOIN " + RetSqlTab("SB1") + " ON SB1.B1_COD = SB7.B7_COD AND SB1.D_E_L_E_T_ = '' AND SB1.B1_FILIAL = '" + xFilial("SB1") + "'"
	cQuery += " WHERE SB7.D_E_L_E_T_ = ''" + CRLF
	cQuery += "   AND SB7.B7_FILIAL = '" + xFilial("SB7") + "'"
	
	if !Empty(cCOdInv)
		cQuery += "   AND SB7.B7_DOC   = '" + cCodInv + "'"
	else
		cQuery += "   AND SB7.B7_DATA   = '" + cData + "'"
	endif
	
	cQuery += "   AND SB7.B7_STATUS = '2'"

	TcQuery cQuery New Alias (cAlias)

	DbSelectArea(cAlias)

	If (cAlias)->(!Eof())
		lRet := .f.
	endif

	(cAlias)->(DbCloseArea())
	
Return lRet
