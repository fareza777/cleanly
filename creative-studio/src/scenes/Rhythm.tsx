import { Backdrop, Brand, Motion, Screen } from "../design";
export const Rhythm = () => (
  <Backdrop dark>
    <div style={{ position: "absolute", top: 75, left: 100 }}>
      <Brand light />
    </div>
    <div style={{ position: "absolute", left: 100, top: 300, width: 660 }}>
      <Motion>
        <div
          style={{
            fontSize: 24,
            fontWeight: 800,
            letterSpacing: 4,
            color: "#B9F3D6",
          }}
        >
          03 / FIND YOUR RHYTHM
        </div>
        <div
          style={{
            fontSize: 91,
            lineHeight: 1.08,
            fontWeight: 800,
            letterSpacing: -4,
            marginTop: 30,
          }}
        >
          Your home.
          <br />
          <span style={{ color: "#B9F3D6" }}>Your routine.</span>
        </div>
      </Motion>
      <Motion delay={12}>
        <div
          style={{
            fontSize: 32,
            lineHeight: 1.5,
            marginTop: 32,
            color: "#D5EADF",
          }}
        >
          Save your own checklists.
          <br />
          Set a daily or weekly reminder.
        </div>
      </Motion>
    </div>
    <div style={{ position: "absolute", left: 850, top: 180 }}>
      <Screen name="routines" width={375} rotate={-4} />
    </div>
    <div style={{ position: "absolute", left: 1320, top: 90 }}>
      <Screen name="schedule" width={395} rotate={3} />
    </div>
  </Backdrop>
);
