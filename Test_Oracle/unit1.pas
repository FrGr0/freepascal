unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, oracleconnection, sqldb, DB, FileUtil, Forms, Controls,
  Graphics, Dialogs, StdCtrls, DBGrids, Menus, ComCtrls, IniFiles;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    ComboBox1: TComboBox;
    Datasource1: TDatasource;
    DBGrid1: TDBGrid;
    Edit1: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    MainMenu1: TMainMenu;
    Edit2: TEdit;
    Memo1: TMemo;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    MenuItem6: TMenuItem;
    MenuItem7: TMenuItem;
    OracleConnection1: TOracleConnection;
    SaveDialog1: TSaveDialog;
    SQLQuery1: TSQLQuery;
    SQLTransaction1: TSQLTransaction;
    StatusBar1: TStatusBar;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure ComboBox1Change(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure MenuItem4Click(Sender: TObject);
    procedure MenuItem5Click(Sender: TObject);
    procedure MenuItem6Click(Sender: TObject);
    procedure MenuItem7Click(Sender: TObject);
    procedure ParseTNS(TNSName: string);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  Form1: TForm1;
  isActive: boolean;

implementation

{$R *.lfm}

{ TForm1 }


procedure TForm1.Button1Click(Sender: TObject);
var
  IniFile: string;
  config: TIniFile;
begin
  if (not isActive) then
  begin
    try
      OracleConnection1.DatabaseName := ComboBox1.Text;
      OracleConnection1.UserName := Edit1.Text;
      OracleConnection1.Password := Edit2.Text;
      OracleConnection1.Connected := True;
      IniFile := GetCurrentDir + '\config.ini';
      config := TIniFile.Create(IniFile);
      config.WriteString(ComboBox1.Text, 'USER', Edit1.Text);
      config.WriteString(ComboBox1.Text, 'PASS', Edit2.Text);
      config.Free;
      SQLTransaction1.Active := True;
      Button1.Caption := 'Déconnecte';
      Button2.Enabled := True;
      isActive := True;
      StatusBar1.Panels[0].Text := 'connecté a ' + ComboBox1.Text;
    finally
    end;
  end
  else
  begin
    SQLTransaction1.Active := False;
    SQLQuery1.Active := False;
    OracleConnection1.Connected := False;
    Button1.Caption := 'Connecte';
    isActive := False;
    Button2.Enabled := False;
    Button3.Enabled := False;
    StatusBar1.Panels[0].Text := 'Non connecté';
  end;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  try
    if not (Memo1.Text = '') then
    begin

      SQLQuery1.Active := False;
      DBGrid1.Clear;
      Button3.Enabled := False;

      if RightStr(Memo1.Text, 1) = ';' then
      begin
        Memo1.Text := LeftStr(Memo1.Text, Length(Memo1.Text) - 1);
      end;

      if lowerCase(Memo1.Text) = 'commit' then
        SQLTransaction1.Commit
      else if lowerCase(Memo1.Text) = 'rollback' then
        SQLTransaction1.Rollback
      else
      begin
        SQLQuery1.SQL.Text := Memo1.Text;
        SQLQuery1.Active := True;
        Button3.Enabled:=True;
      end;
    end;
  finally
  end;
end;

procedure TForm1.Button3Click(Sender: TObject);
var
  I, J: integer;
  SL: TStringList;
begin
  if SaveDialog1.Execute then
  begin
    SL := TStringList.Create;
    SQLQuery1.First;
    for I := 1 to SQLQuery1.RecordCount do
    begin
      SL.Add('');
      SQLQuery1.RecNo := I;
      for J := 0 to SQLQuery1.Fields.Count - 1 do
        SL[SL.Count - 1] := SL[SL.Count - 1] + SQLQuery1.Fields[J].AsString + ';';
    end;
    if FileExists(SaveDialog1.FileName) then
    begin
      if MessageDlg('Suppression', 'Remplacer le fichier existant ?',
        mtConfirmation, [mbYes, mbNo], 0) = mrYes then
      begin
        DeleteFile(SaveDialog1.FileName);
      end;
    end;
    SL.SaveToFile(SaveDialog1.FileName);
    SL.Free;
    StatusBar1.Panels[0].Text :=IntToStr(SQLQuery1.RecordCount) + ' lignes enregistrées';
  end;
end;

procedure TForm1.ComboBox1Change(Sender: TObject);
var
  IniFile: string;
  config: TIniFile;
begin
  try
    IniFile := GetCurrentDir + '\config.ini';
    config := TIniFile.Create(IniFile);
    Edit1.Text := config.ReadString(ComboBox1.Text, 'USER', '');
    Edit2.Text := config.ReadString(ComboBox1.Text, 'PASS', '');
    config.Free;
  finally
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  IniFile: string;
  TNSName: string;
  config: TIniFile;
begin
  IniFile := GetCurrentDir + '\config.ini';

  if not FileExists(IniFile) then
  begin
    TNSName := InputBox('configuration', 'chemin vers TNSName.ora', '');
    config := TIniFile.Create(IniFile);
    config.WriteString('ORA', 'TNS', TNSName);
    config.Free;
  end;
  config := TIniFile.Create(IniFile);
  TNSName := config.ReadString('ORA', 'TNS', '');
  config.Free;
  ParseTNS(TNSName);
end;

procedure TForm1.MenuItem4Click(Sender: TObject);
begin
  Form1.Close;
  Exit;
end;

procedure TForm1.MenuItem5Click(Sender: TObject);
begin
    ShowMessage('peut être un jour...');
end;

procedure TForm1.MenuItem6Click(Sender: TObject);
begin
    ShowMessage('même pas en rêve !');
end;

procedure TForm1.MenuItem7Click(Sender: TObject);
begin
    ShowMessage('temps à perdre = dev des trucs inutiles.');
end;


procedure TForm1.ParseTNS(TNSname: string);
var
  slTemp, slTNSConfig, SL: TStringList;
  sPath, sTemp: string;
  i: integer;
begin
  slTemp := TStringList.Create;
  slTNSConfig := TStringList.Create;
  SL := TStringList.Create;
  try
    sPath := TNSname;
    begin
      slTemp.LoadFromFile(sPath);    // Load tnsnames.ora
      sTemp := StringReplace(StringReplace(UpperCase(slTemp.Text), ' ', '', [rfReplaceAll]),
        ')', '', [rfReplaceAll]);  // delete ')' and spaces
      slTemp.Clear;
      slTemp.Delimiter := '(';
      slTemp.DelimitedText := sTemp;   // parse like  Name=Value
      sTemp := '';

      SL.Sorted := True; // Required for Duplicates to work
      SL.Duplicates := dupIgnore;

      for i := 0 to slTemp.Count - 1 do
      begin
        if pos('DESCRIPTION', slTemp[i]) = 1 then  // Get Name before description
        begin
          sTemp := StringReplace(slTemp[i - 1], '=', '', [rfReplaceAll]);
          //ComboBox1.Items.Add(sTemp);    // Fill combobox
          SL.Add(sTemp);
        end;
        if length(slTemp.ValueFromIndex[i]) > 0 then  //Get filled Name=Value
          slTNSConfig.Add(sTemp + '_' + slTemp[i]);  // Fill TNS config like TNS_HOST=Value
      end;

    end;
  finally
    slTemp.Free;
    slTNSConfig.Free;
    ComboBox1.Items.Assign(SL);
    ComboBox1.Sorted := True;
    SL.Free;

  end;
end;

end.
