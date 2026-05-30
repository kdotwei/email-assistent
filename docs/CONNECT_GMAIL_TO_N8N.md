# 管理 n8n 的使用者認證

1. 進入 n8n Web UI，點開左邊側邊欄
2. 上面有一個加號，按下後選 New Crendential
3. 選 Gamil OAuth
4. Redirect URL 不用改

到這一步時請先去建立 Google OAuth 服務再繼續

5. 放入 Client ID 和 Secret
6. 按下畫面上的 Sign in with Google 按鈕

註：登入畫面可能會顯示這個 APP 不安全還是什麼的，請按下畫面上的 `繼續`。

# 註冊 Google Oauth

https://developers.google.com/identity/protocols/oauth2?hl=zh-tw

1. 在 gpc 新增專案
2. 進入專案（左上角 `Google Claude` 字樣旁邊會有你專案的名字）
3. API 與服務
4. OAuth 同意畫面
5. 用戶端
6. 建立用戶端
7. 應用程式類型 -> 網頁應用程式
8. 名稱 -> 看得懂就好
9. 已授權的重新導向 URI -> 剛剛在 n8n 的 Redirect URL
10. 建立
11. 下載設定檔（裡面有 ID 和 Secret），然後存好。

# 開啟 OAuth 服務的 Gmail 功能

登入 OAuth 之後他可能還是會說沒有開啟 Gmail 服務或無法使用等問題。

這時後進到剛剛的 GCP 專案 -> API 與服務 -> 已啟用的 API 和服務 -> 啟用 API 和服務

-> 去找 Gamil 然後啟用他。
