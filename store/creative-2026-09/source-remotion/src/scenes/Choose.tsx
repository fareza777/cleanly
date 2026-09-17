import { Backdrop, Brand, Motion, Screen } from "../design";
export const Choose = () => (
  <Backdrop>
    <div style={{ position: "absolute", top: 75, left: 100 }}>
      <Brand />
    </div>
    <div style={{ position: "absolute", top: 240, left: 110, width: 890 }}>
      <Motion>
        <div
          style={{
            fontSize: 24,
            fontWeight: 800,
            letterSpacing: 4,
            color: "#087C62",
          }}
        >
          01 / START SMALL
        </div>
        <div
          style={{
            fontSize: 106,
            lineHeight: 1.08,
            letterSpacing: -5,
            fontWeight: 800,
            marginTop: 28,
          }}
        >
          Got 5 minutes?
          <br />
          <span style={{ color: "#087C62" }}>Start there.</span>
        </div>
      </Motion>
      <Motion delay={15}>
        <div style={{ display: "flex", gap: 20, marginTop: 45 }}>
          {[5, 10, 20, 30].map((n) => (
            <div
              key={n}
              style={{
                width: 145,
                height: 112,
                borderRadius: 25,
                background: n === 10 ? "#087C62" : "#DFECE2",
                color: n === 10 ? "white" : "#174E3A",
                display: "flex",
                alignItems: "baseline",
                justifyContent: "center",
                paddingTop: 25,
                fontWeight: 800,
                fontSize: 46,
              }}
            >
              {n}
              <span style={{ fontSize: 19, marginLeft: 7 }}>min</span>
            </div>
          ))}
        </div>
        <div style={{ fontSize: 32, lineHeight: 1.6, marginTop: 35 }}>
          Choose a room, or try a quick home reset.
        </div>
      </Motion>
    </div>
    <div style={{ position: "absolute", right: 160, top: 50 }}>
      <Screen name="rooms" width={446} />
    </div>
  </Backdrop>
);
