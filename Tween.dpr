program Tween;

uses
  Forms,
  ScreenTween in 'ScreenTween.pas' {FormTween};

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TFormTween, FormTween);
  Application.Run;
end.
