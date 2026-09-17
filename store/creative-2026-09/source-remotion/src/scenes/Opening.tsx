import { useCurrentFrame, interpolate } from "remotion";
import { Backdrop, Brand, Motion, P, Screen, Spark } from "../design";
export const Opening = () => {
  const f = useCurrentFrame();
  return (
    <Backdrop dark>
      <div style={{ position: "absolute", top: 75, left: 100 }}>
        <Brand light />
      </div>
      <div style={{ position: "absolute", left: 110, top: 275, width: 880 }}>
        <Motion>
          <div
            style={{
              fontSize: 24,
              letterSpacing: 4,
              color: "#B9F3D6",
              fontWeight: 800,
            }}
          >
            A FRESH START, NOT A BIG PROJECT.
          </div>
          <div
            style={{
              fontSize: 108,
              lineHeight: 1.04,
              letterSpacing: -6,
              fontWeight: 800,
              marginTop: 34,
            }}
          >
            Less overwhelm.
            <br />
            <span style={{ color: "#B9F3D6" }}>More done.</span>
          </div>
        </Motion>
        <Motion delay={14}>
          <div
            style={{
              fontSize: 35,
              lineHeight: 1.5,
              marginTop: 35,
              maxWidth: 730,
              color: "#D5EADF",
            }}
          >
            A cleaning checklist for the time
            <br />
            you actually have.
          </div>
        </Motion>
      </div>
      <div
        style={{
          position: "absolute",
          right: 165,
          top: 70,
          translate: `0 ${interpolate(f, [0, 195], [22, -12])}px`,
        }}
      >
        <Screen name="home" width={435} rotate={-3} />
      </div>
      <div style={{ position: "absolute", right: 60, top: 800, color: P.gold }}>
        <Spark size={110} />
      </div>
      <div
        style={{
          position: "absolute",
          left: 115,
          bottom: 100,
          fontSize: 26,
          color: "#B9F3D6",
        }}
      >
        Pick your time. Take the first step.
      </div>
    </Backdrop>
  );
};
