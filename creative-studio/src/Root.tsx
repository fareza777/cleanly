import { Composition, Still } from "remotion";
import { Campaign } from "./Campaign";
import { cards, StoreCard, Icon, Feature, ContactSheet } from "./Store";
export const RemotionRoot = () => (
  <>
    <Composition
      id="Cleanly-Fresh-Start"
      component={Campaign}
      durationInFrames={1200}
      fps={30}
      width={1920}
      height={1080}
    />
    {cards.map((c, i) => (
      <Still
        key={c.file}
        id={c.file}
        component={StoreCard}
        width={1080}
        height={1920}
        defaultProps={{ index: i }}
      />
    ))}
    <Still id="Cleanly-Feature" component={Feature} width={1024} height={500} />
    <Still id="Cleanly-Icon" component={Icon} width={512} height={512} />
    <Still
      id="Cleanly-Icon-Master"
      component={Icon}
      width={1024}
      height={1024}
    />
    <Still
      id="Cleanly-Contact"
      component={ContactSheet}
      width={1194}
      height={1080}
    />
  </>
);
