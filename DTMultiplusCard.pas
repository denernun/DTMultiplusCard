unit DTMultiplusCard;

interface

uses
  System.SysUtils,
  System.Types,
  Winapi.Windows,
  Vcl.Forms,
  System.Classes,
  system.StrUtils,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  Vcl.Controls,
  uFuncoesDLL,
  Vcl.Graphics;


type TOperacao = (tpMult_DEBITO_A_VISTA, tpMult_DEBITO, tpMult_CREDITO, tpMult_CREDITO_A_VISTA, tpMult_CREDITO_PARC_LOJA, tpMult_CREDITO_PARC_ADM, tpMult_FROTA, tpMult_VOUCHER,
                  tpMult_PRE_AUTORIZACAO, tpMult_CONF_PRE_AUTORIZACAO, tpMult_CANC_PRE_AUTORIZACAO,
                  tpMult_CONSULTA_SALDO_CREDITO, tpMult_CONSULTA_SALDO_DEBITO,
                  tpMult_EXCLUIR_BINS, tpMult_REIMPRESSAO, tpMult_COLETA_DE_CPF,
                  tpMult_OPCOES_PSP, tpMult_PSP_CLIENTE, tpMult_MERCADO_PAGO, tpMult_PICPAY, tpMult_CANCELAR_ESTORNO, tpMult_STATUS_TRANSACAO
                  );

type
TOnLogEvent    = procedure(Sender: TObject; const Conteudo: string) of object;
TOnComprovante = procedure(Sender: TObject; const Conteudo: string) of object;
TOnQrCode      = procedure(Sender: TObject; const Conteudo: string) of object;
TOnCPF         = procedure(Sender: TObject; const Conteudo: string) of object;
TOnErro        = procedure(Sender: TObject; const Conteudo: string) of object;

type
  TDTMultiplusCard = class(TComponent)
  private
    arq            : TextFile;
    Retorno        : Integer;
    mydata         : TDateTime;
    FOnLog         : TOnLogEvent;
    arrMsg         : TArray<string>;
    fMensagem      : TForm;
    lMensagem      : TLabel;
    eResposta      : TEdit;
    bOk            : TButton;
    bCancelar      : TButton;
    FComprovante   : TOnComprovante;
    FOnCPF         : TOnCPF;
    FPDV: String;
    FCNPJ: string;
    FCodLoja: string;
    FComunicacao: string;
    FData: string;
    FOnErro: TOnErro;
    FOnQrCode: TOnQrCode;


    procedure DoLog(const Conteudo: string);
    procedure DoComprovante(const Conteudo: string);
    procedure DoQrCode(const Conteudo: string);
    procedure DoCPF(const Conteudo: string);
    procedure DoErro(const Conteudo: string);

    procedure CriarArquivo (sNomeArquivo, strMsg, strStackTrace : string);
    procedure VerificaArquivo (sNomeArquivo : string);
    function GetParametros(): Boolean;
    function RetornaErro(): Boolean;
    procedure CriarFormMensagem;
    procedure DestruirMensagem;
    procedure BotaoOkClick(Sender: TObject);
    procedure BotaoCancelarClick(Sender: TObject);
    procedure SetDLLPath;

  protected

  public
    constructor Create(Aowner: TComponent);
    destructor Destroy; override;

    function EfetuaTransacao(Op: TOperacao; Cupom, Nsu, Valor : string; Parcela : integer): Boolean;

    procedure AdicionaLog(strMsg, strStackTrace : string);
    function  ArquivoEmUso(caminhoArquivo : string) : Boolean;

  published

    property Comunicacao    : string                      read FComunicacao             write FComunicacao;
    property CNPJ           : string                      read FCNPJ                    write FCNPJ;
    property CodLoja        : string                      read FCodLoja                 write FCodLoja;
    property Data           : string                      read FData                    write FData;
    property PDV            : String                      read FPDV                     write FPDV;
    property OnLog          : TOnLogEvent                 read FOnLog                   write FOnLog;
    property OnComprovante  : TOnComprovante              read FComprovante             write FComprovante;
    property OnQrCode       : TOnQrCode                   read FOnQrCode                write FOnQrCode;
    property OnCPF          : TOnCPF                      read FOnCPF                   write FOnCPF;
    property OnErro         : TOnErro                     read FOnErro                  write FOnErro;

  end;

function IniciaFuncaoMCInterativo(iComando: Integer;
                                  sCnpjCliente: PAnsiChar;
                                  iParcela: Integer;
                                  sCupom: PAnsiChar;
                                  sValor: PAnsiChar;
                                  sNsu: PAnsiChar;
                                  sData: PAnsiChar;
                                  sNumeroPDV: PAnsiChar;
                                  sCodigoLoja: PAnsiChar;
                                  sTipoComunicacao: Integer;
                                  sParametro: PAnsiChar): Integer; stdcall; external 'TefClientmc.dll' delayed;

function AguardaFuncaoMCInterativo(): PAnsiChar; stdcall; external 'TefClientmc.dll' delayed;

function ContinuaFuncaoMCInterativo(sInformacao: PAnsiChar): Integer; stdcall; external 'TefClientmc.dll' delayed

function FinalizaFuncaoMCInterativo(iComando: Integer;
                                    sCnpjCliente: PAnsiChar;
                                    iParcela: Integer;
                                    sCupom: PAnsiChar;
                                    sValor: PAnsiChar;
                                    sNsu: PAnsiChar;
                                    sData: PAnsiChar;
                                    sNumeroPDV: PAnsiChar;
                                    sCodigoLoja: PAnsiChar;
                                    sTipoComunicacao: Integer;
                                    sParametro: PAnsiChar): Integer; stdcall; external 'TefClientmc.dll' delayed;

function CancelarFluxoMCInterativo(): Integer; stdcall; external 'TefClientmc.dll' delayed;

  procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('DT Inovacao', [TDTMultiplusCard]);
end;

procedure TDTMultiplusCard.SetDLLPath;
var
  DLLPath: string;
begin
  DLLPath := ExtractFilePath(ParamStr(0));

  if not DirectoryExists(DLLPath) then
    raise Exception.Create('Diret�rio da DLL n�o encontrado: ' + DLLPath);

  if not SetDllDirectory(PChar(DLLPath)) then
    raise Exception.Create('Falha ao definir o diret�rio da DLL: ' + DLLPath);
end;


procedure TDTMultiplusCard.AdicionaLog(strMsg, strStackTrace: string);
begin
   CriarArquivo('tef',strMsg,strStackTrace);
end;

function TDTMultiplusCard.ArquivoEmUso(caminhoArquivo: string): Boolean;
begin
    try
        AssignFile(arq,caminhoArquivo);
        if FileExists(caminhoArquivo) then
        begin
            Append(arq);
        end
        else
        begin
          Rewrite ( arq );
        end;
        CloseFile(arq);
        Result := False;
    except
        Result := True;
    end;
end;

procedure TDTMultiplusCard.BotaoCancelarClick(Sender: TObject);
begin
    if (Sender is TButton) and (TButton(Sender).Owner is TForm) then
       TForm(TButton(Sender).Owner).ModalResult := mrCancel; // Fecha o formul�rio com resultado Cancelar
end;

procedure TDTMultiplusCard.BotaoOkClick(Sender: TObject);
begin
    if (Sender is TButton) and (TButton(Sender).Owner is TForm) then
       TForm(TButton(Sender).Owner).ModalResult := mrOk; // Fecha o formul�rio com resultado OK
end;

constructor TDTMultiplusCard.Create(Aowner: TComponent);
begin
     inherited Create(Aowner);
end;

procedure TDTMultiplusCard.CriarArquivo(sNomeArquivo, strMsg, strStackTrace: string);
var
mydata                       : TDateTime;
caminho                      : string;
Version,Dummy                : DWORD;
PVersionData                 : pointer;
PFixedFileInfo               : PVSFixedFileInfo;
FixedFileInfoLength          : UINT;
Major, Minor, Release, Build : Integer;
VersionFinal                 : string;
begin
    mydata := Now;

    if string.IsNullOrEmpty(strMsg) and string.IsNullOrEmpty(strStackTrace)then
       Exit;

    If FileExists(ExpandFileName(GetCurrentDir + '\..\..\')+'nlog.txt') then
       Exit;

    If string.IsNullOrEmpty(sNomeArquivo) then
       Exit;

    if ArquivoEmUso(ExpandFileName(GetCurrentDir + '\..\..\') + sNomeArquivo + '.log')THEN
       Exit;

    try
      caminho := Application.ExeName;
      Version := GetFileVersionInfoSize(pChar(caminho),Dummy);

      if Version = 0 then
       exit;

      PVersionData := AllocMem(Version);
      try
          if GetFileVersionInfo(pChar(caminho), 0, Version, PVersionData) = False then
             exit;

          if VerQueryValue(PVersionData, '', pointer(PFixedFileInfo), FixedFileInfoLength) = False then
             exit;
          Major   := PFixedFileInfo^.dwFileVersionMS shr 16;
          Minor   := PFixedFileInfo^.dwFileVersionMS and $FFFF;
          Release := PFixedFileInfo^.dwFileVersionLS shr 16;
          Build   := PFixedFileInfo^.dwFileVersionLS and $FFFF;
      finally
          FreeMem(PVersionData);
      end;
      if (Major or Minor or Release or Build) <> 0 then
          VersionFinal := IntToStr(Major) + '.' + IntToStr(Minor) + '.' + IntToStr(Release) + '.' + IntToStr(Build);

      VerificaArquivo(sNomeArquivo);

      if strMsg <> '' then
      begin
        Append(arq);
        Writeln(arq,PChar(FormatDateTime('dd/MM/yyyy tt', mydata)+ ' v.' + VersionFinal + ' :: ' + strMsg));
      end;

      if (not string.IsNullOrEmpty(strStackTrace)) then
      begin
        Append(arq);
        Writeln(arq,PChar(FormatDateTime('dd/MM/yyyy tt', mydata)+ ' v.' + VersionFinal + ' :: ' + strStackTrace));
      end;

      Close(arq);

    except
    end;

end;

procedure TDTMultiplusCard.CriarFormMensagem;
begin
  fMensagem := TForm.Create(nil);
  try
    // Configura��es do Formul�rio
    fMensagem.BorderStyle := bsSizeToolWin;
    fMensagem.ClientHeight := 242;
    fMensagem.ClientWidth := 438;
    fMensagem.Color := clBtnFace;
    fMensagem.Font.Name := 'Tahoma';
    fMensagem.Font.Size := 8;
    fMensagem.Position := poOwnerFormCenter;
    fMensagem.Caption := 'Mensagem';

    // Label (lMensagem)
    lMensagem := TLabel.Create(fMensagem);
    lMensagem.Parent := fMensagem;
    lMensagem.Left := 8;
    lMensagem.Top := 8;
    lMensagem.Width := 51;
    lMensagem.Height := 13;
    lMensagem.Caption := 'Mensagem';

    // Edit (eResposta)
    eResposta := TEdit.Create(fMensagem);
    eResposta.Parent := fMensagem;
    eResposta.Left := 8;
    eResposta.Top := 213;
    eResposta.Width := 417;
    eResposta.Height := 21;
    eResposta.TabOrder := 0;

    // Bot�o OK (bOK)
    bOK := TButton.Create(fMensagem);
    bOK.Parent := fMensagem;
    bOK.Left := 336;
    bOK.Top := 19;
    bOK.Width := 75;
    bOK.Height := 25;
    bOK.Caption := 'OK';
    bOK.TabOrder := 1;

    // Evento OnClick para o bot�o OK
    bOK.OnClick := BotaoOkClick;

    // Bot�o Cancelar (bCancelar)
    bCancelar := TButton.Create(fMensagem);
    bCancelar.Parent := fMensagem;
    bCancelar.Left := 336;
    bCancelar.Top := 64;
    bCancelar.Width := 75;
    bCancelar.Height := 25;
    bCancelar.Caption := 'Cancelar';
    bCancelar.TabOrder := 2;

    // Evento OnClick para o bot�o Cancelar
    bCancelar.OnClick := BotaoCancelarClick;

  finally

  end;
end;

destructor TDTMultiplusCard.Destroy;
begin
  //FConfig.Free;
  inherited Destroy;
end;

procedure TDTMultiplusCard.DestruirMensagem;
begin
     if Assigned(fMensagem) then
        FreeAndNil(fMensagem);
end;

procedure TDTMultiplusCard.DoComprovante(const Conteudo: string);
begin
    if Assigned(FComprovante) then
       FComprovante(Self, Conteudo);
end;

procedure TDTMultiplusCard.DoCPF(const Conteudo: string);
begin
    if Assigned(FOnCPF) then
       FOnCPF(Self, Conteudo);
end;

procedure TDTMultiplusCard.DoErro(const Conteudo: string);
begin
     if Assigned(FOnErro) then
       FOnErro(Self, Conteudo);
end;

procedure TDTMultiplusCard.DoLog(const Conteudo: string);
begin
     if Assigned(FOnLog) then
       FOnLog(Self, Conteudo);
end;

procedure TDTMultiplusCard.DoQrCode(const Conteudo: string);
begin
    if Assigned(FOnQrCode) then
       FOnQrCode(Self, Conteudo);
end;

function TDTMultiplusCard.GetParametros: Boolean;
begin
    Result := True;
    if FCNPJ.IsEmpty or
       FCodLoja.IsEmpty then
    begin
         Result := False;
         DoErro('Reveja os Dados enviados');
         ShowMessage('Reveja os Dados enviados');
    end;
end;

function TDTMultiplusCard.RetornaErro: Boolean;
begin
   if Retorno = 1 then
  begin
    DoErro('Erro gen�rico na execu��o');
    ShowMessage('Erro gen�rico na execu��o');
  end;
  if Retorno = 30 then
  begin
    DoErro('N�o foi encontrado o caminho do ClientD.exe');
    ShowMessage('N�o foi encontrado o caminho do ClientD.exe');
  end;
  if Retorno = 31 then
  begin
    DoErro('ConfigMC.ini est� vazio');
    ShowMessage('ConfigMC.ini est� vazio');
  end;
  if Retorno = 32 then
  begin
    DoErro('ClientD.exe n�o encontrado');
    ShowMessage('ClientD.exe n�o encontrado');
  end;
  if Retorno = 33 then
  begin
    DoErro('ClientD.exe n�o est� em execu��o');
    ShowMessage('ClientD.exe n�o est� em execu��o');
  end;
  if Retorno = 34 then
  begin
    DoErro('Erro ao iniciar ClientD.exe');
    ShowMessage('Erro ao iniciar ClientD.exe');
  end;
  if Retorno = 35 then
  begin
    DoErro('N�o foi poss�vel criar o arquivo de resposta');
    ShowMessage('N�o foi poss�vel criar o arquivo de resposta');
  end;
  if Retorno = 36 then
  begin
    DoErro('Erro na manipula��o do arquivo de resposta');
    ShowMessage('Erro na manipula��o do arquivo de resposta');
  end;
  if Retorno = 37 then
  begin
    DoErro('Erro na leitura do arquivo ConfigMC.ini');
    ShowMessage('Erro na leitura do arquivo ConfigMC.ini');
  end;
  if Retorno = 38 then
  begin
    DoErro('Valor da transa��o com formato incorreto');
    ShowMessage('Valor da transa��o com formato incorreto');
  end;
  if Retorno = 39 then
  begin
    DoErro('Execut�vel de envio de transa��es n�o encontrado');
    ShowMessage('Execut�vel de envio de transa��es n�o encontrado');
  end;
  if Retorno = 40 then
  begin
    DoErro('CNPJ Inv�lido ou no formato incorreto');
    ShowMessage('CNPJ Inv�lido ou no formato incorreto');
  end;
  if Retorno = 41 then
  begin
    DoErro('ClientD.exe est� em processo de atualiza��o');
    ShowMessage('ClientD.exe est� em processo de atualiza��o');
  end;
  if Retorno = 42 then
  begin
    DoErro('A automa��o n�o est� sendo executada no modo administrador');
    ShowMessage('A automa��o n�o est� sendo executada no modo administrador');
  end;
end;

function TDTMultiplusCard.EfetuaTransacao(Op: TOperacao; Cupom, Nsu, Valor : string; Parcela : integer): Boolean;
var
  vMsg                : TStringList;
  retFim              : Integer;
  arrMsg              : TArray<string>;
  respFMsg            : PAnsiChar;
  strRetAguardaFMCInt : PAnsiChar;
  confirmar           : Boolean;
  operacao            : integer;
  TarrMsg             : Integer;
  vQrCode             : string;
  vpos                : integer;
begin
  if GetParametros then
  begin
    case Op of

      tpMult_DEBITO_A_VISTA          : operacao := 20;
      tpMult_DEBITO                  : operacao := 4;
      tpMult_CREDITO                 : operacao := 1;
      tpMult_CREDITO_A_VISTA         : operacao := 0;
      tpMult_CREDITO_PARC_LOJA       : operacao := 2;
      tpMult_CREDITO_PARC_ADM        : operacao := 3;
      tpMult_FROTA                   : operacao := 11;
      tpMult_VOUCHER                 : operacao := 18;
      tpMult_PRE_AUTORIZACAO         : operacao := 15;
      tpMult_CONF_PRE_AUTORIZACAO    : operacao := 16;
      tpMult_CANC_PRE_AUTORIZACAO    : operacao := 17;
      tpMult_CONSULTA_SALDO_CREDITO  : operacao := 9;
      tpMult_CONSULTA_SALDO_DEBITO   : operacao := 10;
      tpMult_EXCLUIR_BINS            : operacao := 110;
      tpMult_REIMPRESSAO             : operacao := 6;
      tpMult_COLETA_DE_CPF           : operacao := 200;
      tpMult_OPCOES_PSP              : operacao := 50;
      tpMult_PSP_CLIENTE             : operacao := 51;
      tpMult_MERCADO_PAGO            : operacao := 52;
      tpMult_PICPAY                  : operacao := 53;
      tpMult_CANCELAR_ESTORNO        : operacao := 54;
      tpMult_STATUS_TRANSACAO        : operacao := 56;

    end;

    SetDLLPath;

    Retorno := IniciaFuncaoMCInterativo(operacao,
                                        PAnsiChar(AnsiString(FCNPJ)),
                                        parcela,
                                        PAnsiChar(AnsiString(cupom)),
                                        PAnsiChar(AnsiString(valor)),
                                        PAnsiChar(AnsiString(nsu)),
                                        PAnsiChar(AnsiString(FData)),
                                        PAnsiChar(AnsiString(FPDV)),
                                        PAnsiChar(AnsiString(FCodLoja)),
                                        StrToInt(FComunicacao.PadLeft(1,'0')),
                                        '');

    mydata := Now;

    DoLog(FormatDateTime('dd/MM/yyyy', mydata) + '- IniciaFuncaoMCInterativo()');
    AdicionaLog('IniciaFuncaoMCInterativo()', '');

    if (Retorno = 0) then
    begin

      var
        retMsg: PAnsiChar := '';
      var
        strComprovante: string := '';
      var
        nsuRet: string := '';
      var
        strCupom: string := '';

      confirmar := True;
      vMsg := TStringList.Create;

      while (retMsg <> '[ERROABORTAR]') and (retMsg <> '[RETORNO]') and
            (retMsg <> '[ERRODISPLAY]') do
      begin
        strRetAguardaFMCInt := AguardaFuncaoMCInterativo();
        AdicionaLog(strRetAguardaFMCInt, '');

        if Pos('QRCODE=', strRetAguardaFMCInt) > 0 then
        begin
        vQrCode := '';
        vpos    := Pos('QRCODE=', strRetAguardaFMCInt) + 8;
        vQrCode := Copy(strRetAguardaFMCInt, vpos, Length(strRetAguardaFMCInt) - vpos);
        DoQrCode(vQrCode);
        end;

        if strRetAguardaFMCInt <> '' then
        begin
          DoLog(FormatDateTime('dd/MM/yyyy', mydata) + '-' + strRetAguardaFMCInt);
          arrMsg := SplitString(strRetAguardaFMCInt, '#');
          retMsg := PAnsiChar(AnsiString(arrMsg[0]));
        end
        else
        begin
          arrMsg := nil;
          retMsg := '';
        end;

        TarrMsg := Length(arrMsg);

        if retMsg = '[MENU]' then
        begin
          if TarrMsg > 2 then
          begin
            CriarFormMensagem;
            lMensagem.Caption := arrMsg[2].Replace('|', sLineBreak);
          end
          else
          begin
            CriarFormMensagem;
            fMensagem.Caption := arrMsg[0];
            lMensagem.Caption := arrMsg[1].Replace('|', sLineBreak);
          end;

          fMensagem.ShowModal;

          if fMensagem.ModalResult = mrCancel then
          begin
            CancelarFluxoMCInterativo();
            AdicionaLog('CancelarFluxoMCInterativo()', '');
            DoErro('Fluxo Cancelado');
            ShowMessage('Fluxo Cancelado');
            retMsg := '[ERROABORTAR]';
            DoLog(FormatDateTime('dd/MM/yyyy', mydata) + ' - Fluxo Cancelado');
            AdicionaLog('Fluxo Cancelado', '');
          end
          else
          begin
            respFMsg := PAnsiChar(AnsiString(eResposta.Text));
            ContinuaFuncaoMCInterativo(respFMsg);
          end;
        end;

        DestruirMensagem;

        if retMsg = '[PERGUNTA]' then
        begin
          CriarFormMensagem;
          fMensagem.Caption := arrMsg[1];
          lMensagem.Caption := arrMsg[2].Replace('|', sLineBreak);
          fMensagem.ShowModal;

          if fMensagem.ModalResult = mrCancel then
          begin
            CancelarFluxoMCInterativo();
            AdicionaLog('CancelarFluxoMCInterativo()', '');
            DoErro('Fluxo Cancelado');
            ShowMessage('Fluxo Cancelado');
            retMsg := '[ERROABORTAR]';
            DoLog(FormatDateTime('dd/MM/yyyy', mydata) + ' - Fluxo Cancelado');
            AdicionaLog('Fluxo Cancelado', '');
          end
          else
          begin
            respFMsg := PAnsiChar(AnsiString(eResposta.Text));
            ContinuaFuncaoMCInterativo(respFMsg);
          end
        end;
        DestruirMensagem;
        if retMsg = '[MSG]' then
        begin
          if TarrMsg >= 2 then
          begin
            if arrMsg[1].Contains('SALDO') and (not arrMsg[1].Contains('RETIRE'))
            then
            begin
              CriarFormMensagem;
              fMensagem.Caption := arrMsg[0];
              lMensagem.Caption := arrMsg[1].Replace('|', sLineBreak);
              fMensagem.ShowModal;
            end;
          end;
        end;
        DestruirMensagem;
        if retMsg = '[ERRODISPLAY]' then
        begin
          DoErro(arrMsg[1].Replace('|', sLineBreak));
          CriarFormMensagem;
          fMensagem.Caption := arrMsg[0];
          lMensagem.Caption := arrMsg[1].Replace('|', sLineBreak);
          fMensagem.ShowModal;

          if fMensagem.ModalResult = mrCancel then
          begin
            CancelarFluxoMCInterativo();
            AdicionaLog('CancelarFluxoMCInterativo()', '');
            DoErro('Fluxo Cancelado');
            ShowMessage('Fluxo Cancelado');
            retMsg := '[ERROABORTAR]';
            DoLog(FormatDateTime('dd/MM/yyyy', mydata) + ' - Fluxo Cancelado');
            AdicionaLog('Fluxo Cancelado', '');
          end
          else
          begin
            respFMsg := PAnsiChar(AnsiString(eResposta.Text));
            ContinuaFuncaoMCInterativo(respFMsg);
          end;
        end;
        DestruirMensagem;
        Sleep(500);

        vMsg := nil;
        vMsg := TStringList.Create;
        respFMsg := nil;
      end;

      if retMsg = '[ERROABORTAR]' then
      begin
        DoErro(retMsg);
        ShowMessage(retMsg);
      end;

      if retMsg = '[RETORNO]' then
      begin

        var
        auxUltimoRet: string := AguardaFuncaoMCInterativo();
        DoLog(FormatDateTime('dd/MM/yyyy', mydata) + auxUltimoRet);

        Sleep(500);

        if TarrMsg > 2 then
        begin
          if (operacao > 50) and (operacao < 60) then
          begin
            try
              FileCreate(Application.ExeName + 'concluiupix.txt');
            except
              on E: Exception do
              begin
                DoErro('Erro - ' + E.Message);
                AdicionaLog('Erro - ' + E.Message, '');
              end;
            end;
          end;

          strCupom := String(arrMsg[15].Replace('CAMPO122=', '').Replace('|', sLineBreak).Replace('CORTAR', '-------------------------------'));

          var
          auxCupom := strCupom + '-------------------------------' + sLineBreak + sLineBreak + strCupom;
          nsuRet   := String(arrMsg[5].Replace('CAMPO0133=', ''));

        end;

        if TarrMsg = 2 then
        begin
          if arrMsg[1].Contains('CPF') then
          begin
            var
            aux      := arrMsg[1].Split(['=']);
            strCupom := 'CPF Coletado: ' + aux[1];
            DoCPF(aux[1]);
          end
          else
          begin
            var
            aux      := arrMsg[1].Replace('RETORNO', '').Replace('|', sLineBreak);
            strCupom := aux;
          end;
        end;

        // ENVIAR DADOS DO COMPROVANTE EM EVENTO
        if Length(strCupom) > 50 then
        DoComprovante(strCupom);
        //DoComprovante(System.String.Join(sLineBreak, arrMsg));

        retFim := 0;

        if (operacao <> 98) and (operacao <> 99) then
        begin
          if confirmar then
          begin
            retFim := FinalizaFuncaoMCInterativo(98,
                      PAnsiChar(AnsiString(FCNPJ)),
                      parcela,
                      PAnsiChar(AnsiString(cupom)),
                      PAnsiChar(AnsiString(valor)),
                      PAnsiChar(AnsiString(nsuRet)),
                      PAnsiChar(AnsiString(FData)),
                      PAnsiChar(AnsiString(FPDV)),
                      PAnsiChar(AnsiString(FCodLoja)),
                      StrToInt(FComunicacao.PadLeft(1,'0')),
                      '');

          end
          else
          begin
            retFim := FinalizaFuncaoMCInterativo(99,
                      PAnsiChar(AnsiString(FCNPJ)),
                      parcela,
                      PAnsiChar(AnsiString(cupom)),
                      PAnsiChar(AnsiString(valor)),
                      PAnsiChar(AnsiString(nsuRet)),
                      PAnsiChar(AnsiString(FData)),
                      PAnsiChar(AnsiString(FPDV)),
                      PAnsiChar(AnsiString(FCodLoja)),
                      StrToInt(FComunicacao.PadLeft(1,'0')),
                      '');
          end;

          AdicionaLog('FinalizaFuncaoMCInterativo()', '');

          var
            strAguardaFMCInt: string := AguardaFuncaoMCInterativo();

          var
            count: Integer := 0;

          while (not strAguardaFMCInt.Contains('RETORNO')) and (count < 15) do
          begin
            DoLog(FormatDateTime('dd/MM/yyyy', mydata) + strAguardaFMCInt);
            strAguardaFMCInt := AguardaFuncaoMCInterativo();
            count            := count + 1;
          end;

          DoLog(FormatDateTime('dd/MM/yyyy', mydata) + strAguardaFMCInt);

        end

        else
        begin
          retFim := 0;
        end;

        if retFim = 0 then
        begin
          DoLog(FormatDateTime('dd/MM/yyyy', mydata) + ' - FIM DA TRANSA��O');
        end
        else
        begin
          DoLog(FormatDateTime('dd/MM/yyyy', mydata) + ' - ERRO: ');
        end;
      end;

    end
    else
    begin
      RetornaErro();
      DoErro('Erro - IniciaFuncaoMCInterativo - Codigo do Erro: ' + Retorno.ToString());
      ShowMessage('Erro - IniciaFuncaoMCInterativo - Codigo do Erro: ' + Retorno.ToString());
      AdicionaLog('Erro - IniciaFuncaoMCInterativo', '');
    end
  end

end;

procedure TDTMultiplusCard.VerificaArquivo(sNomeArquivo: string);
var
  Tamanho : Integer;
  existe  : Boolean;
begin
      Append(arq);
      Tamanho := FileSize(arq);
      existe  := FileExists(ExpandFileName(GetCurrentDir + '\..\..\') + sNomeArquivo + '.log');

      if existe = True and (Tamanho >= 314572800) then
      begin
           try
              DeleteFile(PChar(ExpandFileName(GetCurrentDir + '\..\..\') + sNomeArquivo + '_old.log'));
              MoveFile(PChar(ExpandFileName(GetCurrentDir + '\..\..\') + sNomeArquivo + '.log'),PChar(ExpandFileName(GetCurrentDir + '\..\..\') + sNomeArquivo + '_old.log'));
           except

           end;
      end;

end;

end.
