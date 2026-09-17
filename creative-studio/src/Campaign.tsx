import { AbsoluteFill, interpolate, staticFile } from "remotion";
import { Audio } from "@remotion/media";
import { TransitionSeries, linearTiming } from "@remotion/transitions";
import { fade } from "@remotion/transitions/fade";
import { Opening } from "./scenes/Opening";
import { Choose } from "./scenes/Choose";
import { Guided } from "./scenes/Guided";
import { Rhythm } from "./scenes/Rhythm";
import { Progress } from "./scenes/Progress";
import { Closing } from "./scenes/Closing";
export const Campaign = () => (
  <AbsoluteFill>
    <TransitionSeries>
      <TransitionSeries.Sequence durationInFrames={195}>
        <Opening />
      </TransitionSeries.Sequence>
      <TransitionSeries.Transition
        presentation={fade()}
        timing={linearTiming({ durationInFrames: 15 })}
      />
      <TransitionSeries.Sequence durationInFrames={210}>
        <Choose />
      </TransitionSeries.Sequence>
      <TransitionSeries.Transition
        presentation={fade()}
        timing={linearTiming({ durationInFrames: 15 })}
      />
      <TransitionSeries.Sequence durationInFrames={225}>
        <Guided />
      </TransitionSeries.Sequence>
      <TransitionSeries.Transition
        presentation={fade()}
        timing={linearTiming({ durationInFrames: 15 })}
      />
      <TransitionSeries.Sequence durationInFrames={225}>
        <Rhythm />
      </TransitionSeries.Sequence>
      <TransitionSeries.Transition
        presentation={fade()}
        timing={linearTiming({ durationInFrames: 15 })}
      />
      <TransitionSeries.Sequence durationInFrames={210}>
        <Progress />
      </TransitionSeries.Sequence>
      <TransitionSeries.Transition
        presentation={fade()}
        timing={linearTiming({ durationInFrames: 15 })}
      />
      <TransitionSeries.Sequence durationInFrames={210}>
        <Closing />
      </TransitionSeries.Sequence>
    </TransitionSeries>
    <Audio
      src={staticFile("fresh-start.wav")}
      volume={(f) =>
        interpolate(f, [0, 35, 1140, 1200], [0, 0.72, 0.72, 0], {
          extrapolateLeft: "clamp",
          extrapolateRight: "clamp",
        })
      }
    />
  </AbsoluteFill>
);
