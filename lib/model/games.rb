class Games
  def self.create_games_message_obj
    {
      type: "template",
      altText: "this is doodle games",
      template: {
        type: "carousel",
        columns: [
          {
            thumbnailImageUrl: "#{Settings.base_url}/static/images/games_happy_halloween_2016.jpg",
            title: "ハロウィーン2016!",
            text: "魔法を駆使してクリアを目指せ！",
            actions: [
              {
                type: "uri",
                label: "Play this",
                uri: "https://www.google.com/doodles/halloween-2016"
              }
            ]
          },
          {
            thumbnailImageUrl: "#{Settings.base_url}/static/images/games_block.jpg",
            title: "ブロックくずし",
            text: "おなじみのゲームをGoogle画像検索の画面で！",
            actions: [
              {
                type: "uri",
                label: "Play this",
                uri: "https://www.google.com/search?q=atari+breakout&tbm=isch"
              }
            ]
          },
          {
            thumbnailImageUrl: "#{Settings.base_url}/static/images/games_quick_draw.jpg",
            title: "QUICK, DRAW!",
            text: "画力が試される！人工知能(AI)にお題を伝えろ！！",
            actions: [
              {
                type: "uri",
                label: "Play this",
                uri: "https://quickdraw.withgoogle.com/"
              }
            ]
          },
          {
            thumbnailImageUrl: "#{Settings.base_url}/static/images/games_beethovens.png",
            title: "ベートーベン",
            text: "バラバラになってしまった譜面を音楽を聞きながら順番に並べて！",
            actions: [
              {
                type: "uri",
                label: "Play this",
                uri: "https://www.google.com/doodles/celebrating-ludwig-van-beethovens-245th-year?hl=ja"
              }
            ]
          },
          {
            thumbnailImageUrl: "#{Settings.base_url}/static/images/games_scovilles.png",
            title: "ウィルバー・スコヴィル",
            text: "タイミング良くゲージを合わせて、アイスクリームで唐辛子を撃退しよう！",
            actions: [
              {
                type: "uri",
                label: "Play this",
                uri: "https://www.google.com/doodles/wilbur-scovilles-151st-birthday"
              }
            ]
          }
        ]
      }
    }
  end
end
