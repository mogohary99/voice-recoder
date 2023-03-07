
import 'package:flutter/material.dart';
import 'package:audio_waveforms/audio_waveforms.dart';


enum AudioState { recording, stop, play }

const veryDarkBlue = Color(0xff172133);
const kindaDarkBlue = Color(0xff202641);

void main() {
  runApp(RecordingScreen());
}

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  _RecordingScreenState createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Microphone Flutter',
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }

}
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  AudioState? audioState;
  late final RecorderController recorderController;
  PlayerController controller = PlayerController();
  String? recordPath;
  List<double> waveformData = [];

  @override
  void initState() {
    super.initState();
    _initialiseControllers();
  }
  void _initialiseControllers() {
    recorderController = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.mpeg4
      ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
      ..sampleRate = 44100;
  }
  void startRecording() async {
    if (await recorderController.checkPermission()) {
      await recorderController.record();
    }
  }

  void cancelRecord() async {
    await recorderController.stop();
  }

  void stopRecording() async {
    recordPath = await recorderController.stop();
    await controller.preparePlayer(
      path: recordPath!,
      shouldExtractWaveform: true,
      noOfSamples: 100,
      volume: 1.0,
    );
    print(controller.waveformData);
    print(recordPath);
  }

  void playAudio() async {
    debugPrint("Audio Initialized");
    await controller.startPlayer(finishMode: FinishMode.stop);
    controller.onCompletion.listen((_){
      setState((){
        audioState =AudioState.play;
      });

    }).onDone(()async {
      await controller.seekTo(0);
    });
    /*
    await audioPlayer.play(DeviceFileSource(recordPath!));
    await audioPlayer.getDuration().then((value) {
      debugPrint(value.toString());
    });

     */
  }
  pauseAudio()async{
   await controller.pausePlayer();
  }

  @override
  void dispose() {
    super.dispose();
    recorderController.dispose();
  }

  void handleAudioState(AudioState? state) {
    setState(() {
      if (audioState == null) {
        // Starts recording
        audioState = AudioState.recording;
        startRecording();
        // Finished recording
      } else if (audioState == AudioState.recording) {
        audioState = AudioState.play;
        stopRecording();
        // Play recorded audio
      } else if (audioState == AudioState.play) {
        audioState = AudioState.stop;
        playAudio();
        // Stop recorded audio
      } else if (audioState == AudioState.stop) {
        audioState = AudioState.play;
        pauseAudio();
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: veryDarkBlue,
      appBar: AppBar(
        title: const Text('Voice Recorder'),
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          //  if (waveformData)
              AudioFileWaveforms(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                size: Size(MediaQuery.of(context).size.width, 100.0),
                playerController: controller,
                continuousWaveform: false,
                enableSeekGesture: true,
                waveformType: WaveformType.fitWidth,

                waveformData: controller.waveformData,
                playerWaveStyle: const PlayerWaveStyle(
                  fixedWaveColor: Colors.white54,
                  liveWaveColor: Colors.blueAccent,
                  spacing: 6,
                ),
              ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: handleAudioColour(),
                  ),
                  child: RawMaterialButton(
                    fillColor: Colors.white,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(30),
                    onPressed: () => handleAudioState(audioState),
                    child: getIcon(audioState),
                  ),
                ),
                const SizedBox(width: 20),
                if (audioState == AudioState.play ||
                    audioState == AudioState.stop)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: kindaDarkBlue,
                    ),
                    child: RawMaterialButton(
                      fillColor: Colors.white,
                      shape: const CircleBorder(),
                      padding: EdgeInsets.all(30),
                      onPressed: () => setState(() {
                        audioState = null;
                        controller.dispose();
                      }),
                      child: const Icon(
                        Icons.replay,
                        size: 50,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Color handleAudioColour() {
    if (audioState == AudioState.recording) {
      return Colors.deepOrangeAccent.shade700.withOpacity(0.5);
    } else if (audioState == AudioState.stop) {
      return Colors.green.shade900;
    } else {
      return kindaDarkBlue;
    }
  }

  Icon getIcon(AudioState? state) {
    switch (state) {
      case AudioState.play:
        return const Icon(Icons.play_arrow, size: 50);
      case AudioState.stop:
        return const Icon(Icons.stop, size: 50);
      case AudioState.recording:
        return const Icon(
          Icons.mic,
          color: Colors.redAccent,
          size: 50,
        );
      default:
        return const Icon(Icons.mic, size: 50);
    }
  }
}

