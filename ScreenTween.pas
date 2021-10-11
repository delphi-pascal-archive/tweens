unit ScreenTween;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ComCtrls, StdCtrls, ExtCtrls, ExtDlgs, Spin;

type
  TTween = (twCalculate, twShowList, twIgnore);

  TFormTween = class(TForm)
    ButtonLoadA: TButton;
    ButtonLoadB: TButton;
    ImageA: TImage;
    ImageB: TImage;
    CheckBoxStretch: TCheckBox;
    ImageTween: TImage;
    TrackBarTween: TTrackBar;
    OpenPictureDialogTween: TOpenPictureDialog;
    PanelSequence: TPanel;
    ButtonCreateSequence: TButton;
    SpinEditSequenceCount: TSpinEdit;
    LabelSequenceCount: TLabel;
    ButtonShowSequence: TButton;
    ButtonReset: TButton;
    Label1: TLabel;
    SpinEditDelay: TSpinEdit;
    LabelDelay: TLabel;
    procedure ButtonLoadClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure TrackBarTweenChange(Sender: TObject);
    procedure CheckBoxStretchClick(Sender: TObject);
    procedure ButtonCreateSequenceClick(Sender: TObject);
    procedure ButtonResetClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ButtonShowSequenceClick(Sender: TObject);
  private
    BitmapA      :  TBitmap;
    BitmapB      :  TBitmap;
    ImageSequence:  TList;
    Tween        :  TTween;
    PROCEDURE ShowTweenImage;
    PROCEDURE ResetSequence;
  public
    { Public declarations }
  end;

var
  FormTween: TFormTween;

implementation
{$R *.DFM}

TYPE
  ETweenError = CLASS(Exception);

FUNCTION CreateTweenBitmap(CONST BitmapA:  TBitmap;
                           CONST WeightA:  CARDINAL;
                           CONST BitmapB:  TBitmap;
                           CONST WeightB:  CARDINAL):  TBitmap;
  CONST
    MaxPixelCount = 65536;

  TYPE
    TRGBArray = ARRAY[0..MaxPixelCount-1] OF TRGBTriple;
    pRGBArray = ^TRGBArray;

  VAR
    i         :  INTEGER;
    j         :  INTEGER;
    RowA      :  pRGBArray;
    RowB      :  pRGBArray;
    RowTween  :  pRGBArray;
    SumWeights:  CARDINAL;

  FUNCTION WeightPixels (CONST pixelA, pixelB:  CARDINAL):  BYTE;
  BEGIN
    RESULT := BYTE((WeightA*pixelA + WeightB*pixelB) DIV SumWeights)

  END {WeightPixels};

BEGIN
  IF   (BitmapA.PixelFormat <> pf24bit) OR
       (BitmapB.PixelFormat <> pf24bit)
  THEN RAISE ETweenError.Create('Tween:  PixelFormats must be pf24fit');

  IF   (BitmapA.Width  <> BitmapB.Width) OR
       (BitmapA.Height <> BitmapB.Height)
  THEN RAISE ETweenError.Create('Tween:  Bitmap dimensions are not the same');

  SumWeights := WeightA + WeightB;

  RESULT := TBitmap.Create;
  RESULT.Width  := BitmapA.Width;
  RESULT.Height := BitmapA.Height;
  RESULT.PixelFormat := pf24bit;

  // If SumWeights is 0, just return a "empty" white image
  IF   SumWeights > 0
  THEN BEGIN

    FOR j := 0 TO RESULT.Height-1 DO
    BEGIN
      RowA     := BitmapA.Scanline[j];
      RowB     := BitmapB.Scanline[j];
      RowTween := RESULT.Scanline[j];

      FOR i := 0 TO RESULT.Width-1 DO
      BEGIN
        WITH RowTween[i] DO
        BEGIN
          rgbtRed   := WeightPixels(rowA[i].rgbtRed,   rowB[i].rgbtRed);
          rgbtGreen := WeightPixels(rowA[i].rgbtGreen, rowB[i].rgbtGreen);
          rgbtBlue  := WeightPixels(rowA[i].rgbtBlue,  rowB[i].rgbtBlue)
        END
      END
    END

  END

END {CreateTweenBitmap};


procedure TFormTween.ButtonLoadClick(Sender: TObject);
  VAR
    Bitmap:  TBitmap;
begin
  IF   OpenPictureDialogTween.Execute
  THEN BEGIN
    ResetSequence;

    Bitmap := TBitmap.Create;
    Bitmap.LoadFromFile(OpenPictureDialogTween.Filename);
    IF   (Sender AS TButton).Tag = 1
    THEN BEGIN
      IF   Assigned(BitmapA)
      THEN BitmapA.Free;
      BitmapA := Bitmap;
      ImageA.Picture.Graphic := BitmapA
    END
    ELSE BEGIN
      IF   Assigned(BitmapB)
      THEN BitmapB.Free;
      BitmapB := Bitmap;
      ImageB.Picture.Graphic := BitmapB;
    END;

    IF   Assigned(BitmapA) AND Assigned(BitmapB)
    THEN BEGIN
      IF  (BitmapA.Width       = BitmapB.Width)       AND
          (BitmapA.Height      = BitmapB.Height)      AND
          (BitmapA.PixelFormat = pf24bit)             AND
          (BitmapB.PixelFormat = pf24bit)
      THEN BEGIN
        ShowTweenImage;
        TrackBarTween.Visible := TRUE;
        ImageTween.Visible    := TRUE;
        PanelSequence.Visible := TRUE;
      END
      ELSE BEGIN
        ShowMessage('Bitmaps are not compatible for Tween Operation.' + #$0A +
                    'Sizes are not the same or bitmaps are not 24-bits/pixel.');
        TrackBarTween.Visible := FALSE;
        ImageTween.Visible    := FALSE;
        PanelSequence.Visible := FALSE;
      END
    END
  END
end;


procedure TFormTween.FormCreate(Sender: TObject);
begin
  BitmapA := NIL;
  BitmapB := NIL;
  ImageSequence := TList.Create;
  Tween := twCalculate;
end;


procedure TFormTween.FormDestroy(Sender: TObject);
begin
  ImageSequence.Clear;
  ImageSequence.Free
end;


procedure TFormTween.TrackBarTweenChange(Sender: TObject);
begin
  ShowTweenImage
end;


// Show Tween (i.e., "In-Between") Image
PROCEDURE TFormTween.ShowTweenImage;
  VAR
    Bitmap:  TBitmap;
BEGIN
  CASE Tween OF
    twCalculate:
      BEGIN
        Screen.Cursor := crHourGlass;
        TRY
          Bitmap := CreateTweenBitmap(BitmapA, TrackBarTween.Max-TrackBarTween.Position,
                                      BitmapB, TrackBarTween.Position);
          TRY
            ImageTween.Picture.Graphic := Bitmap
          FINALLY
            Bitmap.Free
          END
        FINALLY
          Screen.Cursor := crDefault
        END
      END;

    twShowList:
      BEGIN
        Bitmap :=  ImageSequence.Items[ TrackBarTween.Position-1 ];
        ImageTween.Picture.Graphic := Bitmap
      END;

    twIgnore:
      // Use this to ignore changes to trackbar while changing grom calculatinng
      // new images to displaying image from generated sequence
  END;
END {CreateTweenImage};


procedure TFormTween.CheckBoxStretchClick(Sender: TObject);
begin
  ImageA.Stretch     := CheckBoxStretch.Checked;
  ImageB.Stretch     := CheckBoxStretch.Checked;
  ImageTween.Stretch := CheckBoxStretch.Checked
end;


procedure TFormTween.ButtonCreateSequenceClick(Sender: TObject);
  VAR
    Bitmap:  TBitmap;
    i     :  INTEGER;
begin
  ButtonShowSequence.Enabled := TRUE;
  ButtonReset.Enabled := TRUE;
  ButtonCreateSequence.Enabled := FALSE;
  SpinEditSequenceCount.Enabled := FALSE;
  Tween := twIgnore;

  TrackBarTween.Min := 1;
  TrackBarTween.Max := SpinEditSequenceCount.Value;
  TrackBarTween.Frequency := TrackBarTween.Max DIV 10;

  Screen.Cursor := crHourGlass;
  TRY
    ImageSequence.Clear;
    FOR i := TracKBarTween.Min TO TrackBarTween.Max DO
    BEGIN
      TrackBarTween.Position := i;
      Bitmap := CreateTweenBitmap(BitmapA, TrackBarTween.Max-TrackBarTween.Position,
                                  BitmapB, TrackBarTween.Position);
      ImageTween.Picture.Graphic := Bitmap;
      ImageSequence.Add(Bitmap);
      Application.ProcessMessages
    END
  FINALLY
    Screen.Cursor := crDefault;
  END;

  Tween := twShowList
end;


PROCEDURE TFormTween.ResetSequence;
  VAR
    Bitmap:  TBitmap;
    i     :  INTEGER;
BEGIN
  ButtonShowSequence.Enabled := FALSE;
  ButtonReset.Enabled := FALSE;
  ButtonCreateSequence.Enabled := TRUE;
  SpinEditSequenceCount.Enabled := TRUE;

  FOR i := ImageSequence.Count - 1 DOWNTO 0 DO
  BEGIN
    // Free the Bitmap
    Bitmap := ImageSequence.Items[i];
    Bitmap.Free;

    // Delete the TList entry
    ImageSequence.Delete(i);
  END;
  ImageSequence.Clear;

  Tween := twCalculate;
END {ResetSequence};


procedure TFormTween.ButtonResetClick(Sender: TObject);
begin
  ResetSequence;
  Tween := twIgnore;

  TrackBarTween.Min := 0;
  TrackBarTween.Max := 100;
  TrackBarTween.Frequency := TrackBarTween.Max DIV 10;

  Tween := twCalculate;
  TrackBarTween.Position := TrackBarTween.Min;

  ShowTweenImage
end;


procedure TFormTween.ButtonShowSequenceClick(Sender: TObject);
  VAR
    Bitmap   :  TBitmap;
    Delay    :  CARDINAL;
    i        :  INTEGER;
    StartTime:  CARDINAL;
    StopTime :  CARDINAL;
begin
  Tween := twIgnore;
  Delay := SpinEditDelay.Value;
  FOR i := TracKBarTween.Min TO TrackBarTween.Max DO
  BEGIN
    StartTime := GetTickCount;
    TrackBarTween.Position := i;
    Bitmap :=  ImageSequence.Items[ TrackBarTween.Position-1 ];
    ImageTween.Picture.Graphic := Bitmap;
    Application.ProcessMessages;  // Force user interface update
    StopTime := GetTickCount;
    IF   (Delay > 0) AND
         (Delay > StopTime - StartTime)
    THEN Sleep(Delay - (StopTime - StartTime))
  END;
  Tween := twShowList
end;

end.
