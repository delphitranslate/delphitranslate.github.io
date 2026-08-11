unit DAT.Core.Terminology;

interface

uses
  DAT.Core.Types;

type
  TTerminologyResolver = class
  public
    class function TryResolve(const AEntry: TTranslationEntry;
      const ATargetLanguage: string; out ATranslation: string): Boolean;
      static;
    class function TryTranslationMemory(const ACatalog: TTranslationCatalog;
      const AEntry: TTranslationEntry; out ATranslation: string): Boolean;
      static;
  end;

implementation

uses
  System.StrUtils,
  System.SysUtils;

function BaseLanguage(const ACode: string): string;
var
  SeparatorAt: Integer;
begin
  Result := LowerCase(StringReplace(Trim(ACode), '_', '-', [rfReplaceAll]));
  SeparatorAt := Pos('-', Result);
  if SeparatorAt > 0 then
    Result := Copy(Result, 1, SeparatorAt - 1);
end;

function ConceptTranslation(const ALanguage, AConcept: string;
  out ATranslation: string): Boolean;
begin
  Result := True;
  if ALanguage = 'es' then
  begin
    if AConcept = 'command.open' then ATranslation := 'Abrir'
    else if AConcept = 'command.close' then ATranslation := 'Cerrar'
    else if AConcept = 'command.save' then ATranslation := 'Guardar'
    else if AConcept = 'command.saveClose' then ATranslation := 'Guardar y cerrar'
    else if AConcept = 'command.cancel' then ATranslation := 'Cancelar'
    else if AConcept = 'command.activate' then ATranslation := 'Activar'
    else if AConcept = 'command.enable' then ATranslation := 'Habilitar'
    else if AConcept = 'command.schedule' then ATranslation := 'Programar'
    else if AConcept = 'noun.schedule' then ATranslation := 'Horario'
    else if AConcept = 'media.play' then ATranslation := 'Reproducir'
    else if AConcept = 'game.play' then ATranslation := 'Jugar'
    else if AConcept = 'instrument.play' then ATranslation := 'Tocar'
    else if AConcept = 'command.move' then ATranslation := 'Mover'
    else if AConcept = 'command.exit' then ATranslation := 'Salir'
    else if AConcept = 'command.help' then ATranslation := 'Ayuda'
    else if AConcept = 'command.settings' then ATranslation := 'Ajustes'
    else if AConcept = 'command.properties' then ATranslation := 'Propiedades'
    else Result := False;
  end
  else if ALanguage = 'fr' then
  begin
    if AConcept = 'command.open' then ATranslation := 'Ouvrir'
    else if AConcept = 'command.close' then ATranslation := 'Fermer'
    else if AConcept = 'command.save' then ATranslation := 'Enregistrer'
    else if AConcept = 'command.saveClose' then ATranslation := 'Enregistrer et fermer'
    else if AConcept = 'command.cancel' then ATranslation := 'Annuler'
    else if AConcept = 'command.activate' then ATranslation := 'Activer'
    else if AConcept = 'command.enable' then ATranslation := 'Activer'
    else if AConcept = 'noun.schedule' then ATranslation := 'Horaire'
    else if AConcept = 'media.play' then ATranslation := 'Lire'
    else if AConcept = 'game.play' then ATranslation := 'Jouer'
    else if AConcept = 'instrument.play' then ATranslation := 'Jouer'
    else Result := False;
  end
  else if ALanguage = 'de' then
  begin
    if AConcept = 'command.open' then ATranslation := 'Öffnen'
    else if AConcept = 'command.close' then ATranslation := 'Schließen'
    else if AConcept = 'command.save' then ATranslation := 'Speichern'
    else if AConcept = 'command.saveClose' then ATranslation := 'Speichern und schließen'
    else if AConcept = 'command.cancel' then ATranslation := 'Abbrechen'
    else if AConcept = 'command.activate' then ATranslation := 'Aktivieren'
    else if AConcept = 'command.enable' then ATranslation := 'Aktivieren'
    else if AConcept = 'noun.schedule' then ATranslation := 'Zeitplan'
    else if AConcept = 'media.play' then ATranslation := 'Wiedergeben'
    else if AConcept = 'game.play' then ATranslation := 'Spielen'
    else if AConcept = 'instrument.play' then ATranslation := 'Spielen'
    else Result := False;
  end
  else if ALanguage = 'it' then
  begin
    if AConcept = 'command.open' then ATranslation := 'Apri'
    else if AConcept = 'command.close' then ATranslation := 'Chiudi'
    else if AConcept = 'command.save' then ATranslation := 'Salva'
    else if AConcept = 'command.saveClose' then ATranslation := 'Salva e chiudi'
    else if AConcept = 'command.cancel' then ATranslation := 'Annulla'
    else if AConcept = 'command.activate' then ATranslation := 'Attiva'
    else if AConcept = 'command.enable' then ATranslation := 'Abilita'
    else if AConcept = 'noun.schedule' then ATranslation := 'Programma'
    else if AConcept = 'media.play' then ATranslation := 'Riproduci'
    else if AConcept = 'game.play' then ATranslation := 'Gioca'
    else if AConcept = 'instrument.play' then ATranslation := 'Suona'
    else Result := False;
  end
  else if ALanguage = 'pt' then
  begin
    if AConcept = 'command.open' then ATranslation := 'Abrir'
    else if AConcept = 'command.close' then ATranslation := 'Fechar'
    else if AConcept = 'command.save' then ATranslation := 'Salvar'
    else if AConcept = 'command.saveClose' then ATranslation := 'Salvar e fechar'
    else if AConcept = 'command.cancel' then ATranslation := 'Cancelar'
    else if AConcept = 'command.activate' then ATranslation := 'Ativar'
    else if AConcept = 'command.enable' then ATranslation := 'Habilitar'
    else if AConcept = 'noun.schedule' then ATranslation := 'Horário'
    else if AConcept = 'media.play' then ATranslation := 'Reproduzir'
    else if AConcept = 'game.play' then ATranslation := 'Jogar'
    else if AConcept = 'instrument.play' then ATranslation := 'Tocar'
    else Result := False;
  end
  else
    Result := False;
end;

class function TTerminologyResolver.TryResolve(
  const AEntry: TTranslationEntry; const ATargetLanguage: string;
  out ATranslation: string): Boolean;
begin
  ATranslation := '';
  Result := (AEntry <> nil) and (AEntry.SemanticConcept <> '') and
    ConceptTranslation(BaseLanguage(ATargetLanguage),
      AEntry.SemanticConcept, ATranslation);
  if Result then
  begin
    if (Pos('&', AEntry.SourceText) > 0) and
       (Pos('&', ATranslation) = 0) then
      ATranslation := '&' + ATranslation;
    if EndsText('...', Trim(AEntry.SourceText)) and
       not EndsText('...', ATranslation) then
      ATranslation := ATranslation + '...';
  end;
end;

class function TTerminologyResolver.TryTranslationMemory(
  const ACatalog: TTranslationCatalog; const AEntry: TTranslationEntry;
  out ATranslation: string): Boolean;
var
  Candidate: TTranslationEntry;
begin
  Result := False;
  ATranslation := '';
  if (ACatalog = nil) or (AEntry = nil) then
    Exit;
  for Candidate in ACatalog.Entries do
    if (Candidate <> AEntry) and
       (Candidate.Status in [tsReviewed, tsApproved]) and
       (Trim(Candidate.TranslatedText) <> '') and
       SameText(Candidate.SourceText, AEntry.SourceText) and
       (((AEntry.SemanticConcept <> '') and
         SameText(Candidate.SemanticConcept, AEntry.SemanticConcept)) or
        ((AEntry.SemanticConcept = '') and
         SameText(Candidate.ContextKind, AEntry.ContextKind))) then
    begin
      ATranslation := Candidate.TranslatedText;
      Exit(True);
    end;
end;

end.
