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
    class function ApplyAuthoritativeTerms(
      const ACatalog: TTranslationCatalog): Integer; static;
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

function ExactSourceTranslation(const ALanguage, ASourceText: string;
  out ATranslation: string): Boolean; forward;

class function TTerminologyResolver.ApplyAuthoritativeTerms(
  const ACatalog: TTranslationCatalog): Integer;
var
  Entry: TTranslationEntry;
  MandatoryText: string;
  IsMandatory: Boolean;
  ResolvedText: string;
begin
  Result := 0;
  if ACatalog = nil then
    Exit;
  for Entry in ACatalog.Entries do
  begin
    if Entry.Status in [tsExcluded, tsObsolete, tsEdited] then
      Continue;
    IsMandatory := ExactSourceTranslation(BaseLanguage(
      ACatalog.Locale.LanguageCode), Entry.SourceText, MandatoryText);
    if not IsMandatory and
      ((Entry.TranslationOrigin = torProjectGlossary) or
       (Entry.Status in [tsReviewed, tsApproved])) then
      Continue;
    if ((Entry.TranslationOrigin in [torUnknown, torGoogle, torDeepL,
      torSuggestion, torTerminology, torProjectGlossary]) or
      (Entry.Status in [tsNeedsTranslation, tsAiDraft, tsMachineTranslated,
       tsSourceChanged, tsError, tsReviewed, tsApproved])) and
      TryResolve(Entry, ACatalog.Locale.LanguageCode, ResolvedText) and
      not SameText(Trim(Entry.TranslatedText), Trim(ResolvedText)) then
    begin
      Entry.TranslatedText := ResolvedText;
      Entry.Status := tsMachineTranslated;
      Entry.TranslationOrigin := torTerminology;
      Entry.TranslationConfidence := 'terminology';
      Entry.TranslationReviewNote := '';
      Inc(Result);
    end;
  end;
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
    else if AConcept = 'command.add' then ATranslation := 'Agregar'
    else if AConcept = 'command.delete' then ATranslation := 'Eliminar'
    else if AConcept = 'command.openAll' then ATranslation := 'Abrir todo'
    else if AConcept = 'command.closeAll' then ATranslation := 'Cerrar todo'
    else if AConcept = 'noun.language' then ATranslation := 'Idioma'
    else if AConcept = 'calendar.monday' then ATranslation := 'Lun'
    else if AConcept = 'calendar.tuesday' then ATranslation := 'Mar'
    else if AConcept = 'calendar.wednesday' then ATranslation := 'Mi' + #$00E9
    else if AConcept = 'calendar.thursday' then ATranslation := 'Jue'
    else if AConcept = 'calendar.friday' then ATranslation := 'Vie'
    else if AConcept = 'calendar.saturday' then ATranslation := 'S' + #$00E1 + 'b'
    else if AConcept = 'calendar.sunday' then ATranslation := 'Dom'
    else if AConcept = 'media.playSchedule' then ATranslation := 'Horario de reproducci' + #$00F3 + 'n'
    else if AConcept = 'media.showRemainingSchedule' then ATranslation := 'Mostrar horario restante'
    else if AConcept = 'media.playDates' then ATranslation := 'Fechas:'
    else if AConcept = 'media.playTime' then ATranslation := 'Hora(s):'
    else if AConcept = 'media.clockTime' then ATranslation := 'Hora'
    else if AConcept = 'media.song' then ATranslation := 'Canci' + #$00F3 + 'n'
    else if AConcept = 'media.songPurpose' then ATranslation := 'Canci' + #$00F3 + 'n/Motivo'
    else if AConcept = 'noun.type' then ATranslation := 'Tipo'
    else if AConcept = 'media.timesToPlay' then ATranslation := 'Veces:'
    else if AConcept = 'media.playFollowingDays' then ATranslation := 'Reproducir en los siguientes d' + #$00ED + 'as:'
    else if AConcept = 'media.playDateFrom' then ATranslation := 'Fecha inicial'
    else if AConcept = 'media.playDateTo' then ATranslation := 'Fecha final'
    else if AConcept = 'noun.group' then ATranslation := 'Grupo'
    else if AConcept = 'media.pause' then ATranslation := 'Pausar'
    else if AConcept = 'media.stop' then ATranslation := 'Detener'
    else if AConcept = 'media.playing' then ATranslation := 'Reproduciendo'
    else if AConcept = 'media.paused' then ATranslation := 'En pausa'
    else if AConcept = 'media.stopped' then ATranslation := 'Detenido'
    else if AConcept = 'command.refresh' then ATranslation := 'Actualizar'
    else if AConcept = 'noun.themes' then ATranslation := 'Temas'
    else if AConcept = 'media.songName' then ATranslation := 'Nombre de la canci' + #$00F3 + 'n'
    else if AConcept = 'media.duration' then ATranslation := 'Duraci' + #$00F3 + 'n'
    else if AConcept = 'calendar.dateTime' then ATranslation := 'Fecha/hora'
    else if AConcept = 'noun.event' then ATranslation := 'Evento'
    else if AConcept = 'schedule.enabled' then ATranslation := 'Horario activado'
    else if AConcept = 'schedule.disabled' then ATranslation := 'Horario desactivado'
    else if AConcept = 'runtime.uptime' then
      ATranslation := '     Tiempo de actividad:       %d a' + #$00F1 +
        'os       %d meses       %d semanas       %d d' + #$00ED +
        'as       %d horas       %d minutos        %d segundos'
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
    else if AConcept = 'command.add' then ATranslation := 'Ajouter'
    else if AConcept = 'command.delete' then ATranslation := 'Supprimer'
    else if AConcept = 'calendar.monday' then ATranslation := 'Lun'
    else if AConcept = 'calendar.tuesday' then ATranslation := 'Mar'
    else if AConcept = 'calendar.wednesday' then ATranslation := 'Mer'
    else if AConcept = 'calendar.thursday' then ATranslation := 'Jeu'
    else if AConcept = 'calendar.friday' then ATranslation := 'Ven'
    else if AConcept = 'calendar.saturday' then ATranslation := 'Sam'
    else if AConcept = 'calendar.sunday' then ATranslation := 'Dim'
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
    else if AConcept = 'command.add' then ATranslation := 'Hinzuf' + #$00FC + 'gen'
    else if AConcept = 'command.delete' then ATranslation := 'L' + #$00F6 + 'schen'
    else if AConcept = 'calendar.monday' then ATranslation := 'Mo'
    else if AConcept = 'calendar.tuesday' then ATranslation := 'Di'
    else if AConcept = 'calendar.wednesday' then ATranslation := 'Mi'
    else if AConcept = 'calendar.thursday' then ATranslation := 'Do'
    else if AConcept = 'calendar.friday' then ATranslation := 'Fr'
    else if AConcept = 'calendar.saturday' then ATranslation := 'Sa'
    else if AConcept = 'calendar.sunday' then ATranslation := 'So'
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
    else if AConcept = 'command.add' then ATranslation := 'Aggiungi'
    else if AConcept = 'command.delete' then ATranslation := 'Elimina'
    else if AConcept = 'calendar.monday' then ATranslation := 'Lun'
    else if AConcept = 'calendar.tuesday' then ATranslation := 'Mar'
    else if AConcept = 'calendar.wednesday' then ATranslation := 'Mer'
    else if AConcept = 'calendar.thursday' then ATranslation := 'Gio'
    else if AConcept = 'calendar.friday' then ATranslation := 'Ven'
    else if AConcept = 'calendar.saturday' then ATranslation := 'Sab'
    else if AConcept = 'calendar.sunday' then ATranslation := 'Dom'
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
    else if AConcept = 'command.add' then ATranslation := 'Adicionar'
    else if AConcept = 'command.delete' then ATranslation := 'Excluir'
    else if AConcept = 'calendar.monday' then ATranslation := 'Seg'
    else if AConcept = 'calendar.tuesday' then ATranslation := 'Ter'
    else if AConcept = 'calendar.wednesday' then ATranslation := 'Qua'
    else if AConcept = 'calendar.thursday' then ATranslation := 'Qui'
    else if AConcept = 'calendar.friday' then ATranslation := 'Sex'
    else if AConcept = 'calendar.saturday' then ATranslation := 'S' + #$00E1 + 'b'
    else if AConcept = 'calendar.sunday' then ATranslation := 'Dom'
    else Result := False;
  end
  else
    Result := False;
end;

function ExactSourceTranslation(const ALanguage, ASourceText: string;
  out ATranslation: string): Boolean;
var
  TextValue: string;
begin
  Result := False;
  ATranslation := '';
  TextValue := Trim(StringReplace(ASourceText, '&', '', [rfReplaceAll]));
  if ALanguage = 'es' then
  begin
    if SameText(TextValue, 'Time') then
      ATranslation := 'Hora'
    else if SameText(TextValue, 'Type') then
      ATranslation := 'Tipo'
    else if SameText(TextValue, 'Song') then
      ATranslation := 'Canci' + #$00F3 + 'n'
    else if SameText(TextValue, 'Song/Purpose') then
      ATranslation := 'Canci' + #$00F3 + 'n/Motivo'
    else if SameText(TextValue, 'Play Date From') then
      ATranslation := 'Fecha inicial'
    else if SameText(TextValue, 'Play Date To') then
      ATranslation := 'Fecha final'
    else if MatchText(TextValue, ['Play Time', 'Play Time(s)', 'Time(s)',
      'Hours of play', 'Playback hours']) then
      ATranslation := 'Hora(s)'
    else
      Exit(False);
    Exit(True);
  end;
end;

class function TTerminologyResolver.TryResolve(
  const AEntry: TTranslationEntry; const ATargetLanguage: string;
  out ATranslation: string): Boolean;
begin
  ATranslation := '';
  if AEntry = nil then
    Exit(False);
  Result := (AEntry.SemanticConcept <> '') and
    ConceptTranslation(BaseLanguage(ATargetLanguage), AEntry.SemanticConcept,
      ATranslation);
  if not Result then
    Result := ExactSourceTranslation(BaseLanguage(ATargetLanguage),
      AEntry.SourceText, ATranslation);
  if Result then
  begin
    if (Pos('&', AEntry.SourceText) > 0) and
       (Pos('&', ATranslation) = 0) then
      ATranslation := '&' + ATranslation;
    if EndsText('...', Trim(AEntry.SourceText)) and
       not EndsText('...', ATranslation) then
      ATranslation := ATranslation + '...';
    if EndsText(':', Trim(AEntry.SourceText)) and
       not EndsText(':', ATranslation) then
      ATranslation := ATranslation + ':';
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
