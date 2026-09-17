import { AbsoluteFill, Img, staticFile, useVideoConfig } from "remotion";
import { Backdrop, Brand, Fonts, Mark, P, Screen, Spark } from "./design";
export const cards = [
  {
    file: "01-less-overwhelm",
    screen: "home",
    label: "A LITTLE CLEAN. A FRESH START.",
    title: ["Less overwhelm.", "More done."],
    sub: "A cleaning checklist for the time you have.",
    dark: true,
    accent: "#B9F3D6",
    note: "Pick your time. Take the first step.",
  },
  {
    file: "02-your-time",
    screen: "rooms",
    label: "YOUR TIME. YOUR STARTING POINT.",
    title: ["Got 5 minutes?", "Start there."],
    sub: "Choose a room. Get a ready-to-go checklist.",
    dark: false,
    accent: "#087C62",
    note: "5 · 10 · 20 · 30 minute sessions",
  },
  {
    file: "03-guided-checklist",
    screen: "session",
    label: "FROM WHAT NOW TO WHAT’S NEXT.",
    title: ["One task.", "Then the next."],
    sub: "A clear next step. A timer to keep you going.",
    dark: false,
    accent: "#986410",
    note: "Pause whenever life happens.",
  },
  {
    file: "04-routines",
    screen: "routines",
    label: "MAKE YOUR OWN KIND OF CLEAN.",
    title: ["Your home.", "Your routine."],
    sub: "Save the steps you want to come back to.",
    dark: true,
    accent: "#B9F3D6",
    note: "Custom checklists · Ready-made templates",
  },
  {
    file: "05-schedule",
    screen: "schedule",
    label: "A GENTLE NUDGE, RIGHT ON TIME.",
    title: ["Less remembering.", "More rhythm."],
    sub: "Daily or weekly reminders that fit your life.",
    dark: false,
    accent: "#087C62",
    note: "Choose the day, time, room, and duration.",
  },
  {
    file: "06-progress",
    screen: "history",
    label: "SMALL CLEANS ADD UP.",
    title: ["See your effort", "take shape."],
    sub: "Track your minutes, sessions, and streaks.",
    dark: false,
    accent: "#087C62",
    note: "Your week, one little win at a time.",
  },
  {
    file: "07-finish",
    screen: "completion",
    label: "PROGRESS OVER PERFECTION.",
    title: ["Done feels", "really good."],
    sub: "Celebrate the steps you checked off.",
    dark: false,
    accent: "#986410",
    note: "A clearer space. A well-earned pause.",
  },
  {
    file: "08-dark-mode",
    screen: "dark",
    label: "A CALMER WAY TO CLEAN.",
    title: ["Less glare.", "Same fresh start."],
    sub: "Switch to dark mode. Keep your rhythm.",
    dark: true,
    accent: "#B9F3D6",
    note: "Core cleaning tools work offline. No account.",
  },
];
export const StoreCard = ({ index = 0 }: { index?: number }) => {
  const c = cards[index];
  return (
    <Backdrop dark={c.dark}>
      <div
        style={{
          position: "absolute",
          top: 55,
          left: 64,
          right: 64,
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
        }}
      >
        <Brand light={c.dark} small />
        <span style={{ fontSize: 22, opacity: 0.55 }}>0{index + 1} / 08</span>
      </div>
      <div style={{ position: "absolute", top: 150, left: 68, right: 56 }}>
        <div
          style={{
            fontSize: 22,
            fontWeight: 800,
            letterSpacing: 2.8,
            color: c.accent,
            marginBottom: 26,
          }}
        >
          {c.label}
        </div>
        <div
          style={{
            fontSize: index === 4 ? 76 : 88,
            lineHeight: 1.08,
            fontWeight: 800,
            letterSpacing: -4.4,
          }}
        >
          {c.title[0]}
          <br />
          <span style={{ color: c.accent }}>{c.title[1]}</span>
        </div>
        <div
          style={{
            fontSize: 30,
            lineHeight: 1.4,
            marginTop: 24,
            opacity: 0.78,
            maxWidth: 920,
          }}
        >
          {c.sub}
        </div>
      </div>
      <div style={{ position: "absolute", top: 510, left: 226 }}>
        <Screen name={c.screen} width={628} />
      </div>
      <div
        style={{
          position: "absolute",
          left: 62,
          top: 700,
          color: c.accent,
          rotate: "-12deg",
          opacity: 0.9,
        }}
      >
        <Spark size={80} />
      </div>
      <div
        style={{
          position: "absolute",
          right: 68,
          top: 1440,
          color: c.accent,
          opacity: 0.65,
        }}
      >
        <Spark size={46} />
      </div>
      <div
        style={{
          position: "absolute",
          bottom: 39,
          left: 50,
          right: 50,
          textAlign: "center",
          fontSize: 23,
          color: c.dark ? "#D5EADF" : "#476357",
        }}
      >
        {c.note}
      </div>
    </Backdrop>
  );
};
export const Feature = () => (
  <AbsoluteFill
    style={{ fontFamily: "Jakarta", background: P.deep, color: "#F6FAEF" }}
  >
    <Fonts />
    <Img
      src={staticFile("room-campaign.png")}
      style={{ width: "100%", height: "100%", objectFit: "cover" }}
    />
    <div style={{ position: "absolute", top: 56, left: 66 }}>
      <div style={{ fontSize: 27, fontWeight: 800, letterSpacing: -0.9 }}>
        Cleanly
      </div>
      <div
        style={{ fontSize: 14, letterSpacing: 2, marginTop: 8, opacity: 0.8 }}
      >
        CLEANING CHECKLIST
      </div>
      <div
        style={{
          fontWeight: 800,
          fontSize: 55,
          lineHeight: 1.12,
          letterSpacing: -2.5,
          marginTop: 47,
        }}
      >
        Small cleans.
        <br />
        <span style={{ color: "#B9F3D6" }}>Fresh starts.</span>
      </div>
      <div
        style={{
          fontSize: 18,
          lineHeight: 1.5,
          marginTop: 24,
          color: "#D8EEDF",
        }}
      >
        Your time. Your space. Your pace.
      </div>
    </div>
  </AbsoluteFill>
);
export const Icon = () => {
  const { width } = useVideoConfig();
  return (
    <AbsoluteFill
      style={{
        background: "linear-gradient(165deg,#1BC09A 0%,#087158 100%)",
        alignItems: "center",
        justifyContent: "center",
        color: "white",
      }}
    >
      <Mark size={width} />
    </AbsoluteFill>
  );
};
export const ContactSheet = () => (
  <AbsoluteFill
    style={{ background: "#E6ECE6", padding: 30, fontFamily: "Jakarta" }}
  >
    <Fonts />
    <div
      style={{ fontSize: 34, fontWeight: 800, marginBottom: 20, color: P.deep }}
    >
      Cleanly / Play Store creative collection
    </div>
    <div
      style={{
        display: "grid",
        gridTemplateColumns: "repeat(4, 270px)",
        gap: 18,
      }}
    >
      {cards.map((c, i) => (
        <div
          key={c.file}
          style={{
            width: 270,
            height: 480,
            position: "relative",
            overflow: "hidden",
            boxShadow: "0 4px 14px #1233",
          }}
        >
          <div
            style={{
              width: 1080,
              height: 1920,
              position: "absolute",
              scale: 0.25,
              transformOrigin: "0 0",
            }}
          >
            <StoreCard index={i} />
          </div>
        </div>
      ))}
    </div>
  </AbsoluteFill>
);
