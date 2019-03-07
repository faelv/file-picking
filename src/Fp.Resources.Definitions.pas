unit Fp.Resources.Definitions;

interface

const

  APP_TITLE: String = 'FilePicking';
  APP_DATA_FOLDER: String = 'FilePicking';
  APP_SETTINGS_FILE: String = 'settings.xml';
  APP_INSTANCE_EVNT: String = 'FilePicking.Initialized';
  APP_DEVELOPER: String = 'faelv';

  LANG_FILE_TEMPLATE: String = 'locales\%d\language.xml';
  LANG_DEFAULT_LOCALE: Integer = 1033;

  TIME_TEMPLATE: String = 'hh:nn:ss';
  SPEED_TEMPLATE: String = '%s/s';
  PROGRESS_TEMPLATE: String = '%d %s %d - %s %s %s (%d%%)';
  STATUS_TEMPLATE: String = '%s (%d%%)';
  STATUS_TEMPLATE_ERR: String = '%s (%s)';
  TITLE_TEMPLATE: String = '%s (%d%%%s)';

  DEF_FILE_EXT: String = 'xml';
  ZERO_TIME: String = '00:00:00';
  ZERO_PROGRESS: String = '-';

  DEF_SIZE_THRESHOLD: Int64 = 30 * 1024 * 1024; //30MB
  STATUS_UPDT_DELAY: Integer = 0;
  STATUS_TREE_DELAY: Integer = 15;

  INLINE_PROGRESS_BRUSH: Cardinal = $0086EB7E;
  INLINE_PROGRESS_PEN: Cardinal = $00F0F0F0;

implementation

end.
