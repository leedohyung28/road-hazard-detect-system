# selenium 4
from selenium import webdriver
from selenium.webdriver.chrome.service import Service as ChromeService
from webdriver_manager.chrome import ChromeDriverManager
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.common.by import By
from selenium.webdriver.common.action_chains import ActionChains
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import Select

from pynput.keyboard import Key, Controller
from geopy.geocoders import Nominatim

import requests
import re
import time

URL_login = 'https://www.safetyreport.go.kr/#/main/login/login'
URL_report = 'https://www.safetyreport.go.kr/#safereport/safereport'


# sample_account = 'csd0946' 
# sample_password = 'sanggyu6319!'
#sample_address = "충청남도 천안시 동남구 충절로 1600"

Reprot_TITLE = '포트홀 신고'
Reprot_Content = '포트홀 신고합니다.'

geo_local = Nominatim(user_agent= 'South Korea', timeout=None) #위치 생성자
driver = webdriver.Chrome(service=ChromeService(ChromeDriverManager().install())) #웹드라이버 생성

#서버로부터 포트홀 위치 / 사용자 정보 받아오기
def get_user():
    response = requests.get("http://api.cse-detection.kro.kr/get-list")
    
    res = response.json()
    
    return res

#신고 확인
def report(id):
    response = requests.put("http://api.cse-detection.kro.kr/report/" + str(id))
    
    res = response.json()
    
    if (response.status_code >= 200 & response.status_code < 400):
        return res

#주소 형태 변환
def format_address(address):
    # 우편번호 숫자 제거
    address_no_zip = re.sub(r'\b\d{5}(?:-\d{4})?\b', '', address)
    # 쉼표를 기준으로 문자열을 분할하고, 역순으로 결합
    parts = address_no_zip.split(', ')
    reversed_parts = parts[::-1]
    formatted_address = ' '.join(reversed_parts)
    return formatted_address.strip()  # 문자열 양쪽의 공백 제거

#주소 변환
def geocoding_reverse(latitude, longitude):
    try:
        ad = geo_local.reverse([latitude, longitude], exactly_one=True, language='ko')
        return ad.address
    except:
        return [0, 0]
    
#로그인 
def login(driver,account,password):       
    driver.get(url=URL_login)
    driver.maximize_window()
    driver.implicitly_wait(4)
    
    # ID입력
    id_box = driver.find_element(By.CSS_SELECTOR, "#username")
    id_box.click()
    id_box.send_keys(account)
    
    # PW입력
    password_box = driver.find_element(By.CSS_SELECTOR, '#password')
    password_box.click()
    password_box.send_keys(password)
    # time.sleep(1.5) #영상 촬영을 위한 딜레이
    
    # 로그인 버튼 클릭
    login_btn = driver.find_element(By.CSS_SELECTOR, "#contents > div > ul > li.active > article > div:nth-child(2) > p:nth-child(3) > button")
    login_btn.click()
    
    # 대기
    time.sleep(1.5)
    
#신고페이지로 이동
def navigate_to_report_page(driver, re_url):
    driver.get(url=URL_report)

    #대기
    time.sleep(1.5)
    
#경고 팝업 제어
def handle_alert(driver):
    # 경고창이 나타날 때까지 대기
    WebDriverWait(driver, 2).until(EC.alert_is_present())
    
    # 경고창을 전환하여 '취소'를 클릭 (만약 '취소' 버튼이 없다면 '확인'을 클릭)
    alert = driver.switch_to.alert
    alert.dismiss()  # '취소' 버튼을 클릭. '확인'을 클릭하려면 alert.accept()
    print("경고창을 닫았습니다.")
    
def accept_alert(driver):
    # 경고창이 나타날 때까지 대기
    WebDriverWait(driver, 2).until(EC.alert_is_present())
    
    # 경고창을 전환하여 '확인'을 클릭
    alert = driver.switch_to.alert
    alert.accept()  # '확인'을 클릭
    print("확인을 눌렀습니다.")    
    
#신고 FLOW (Targeting)
def reportFLOW(address):
    # 신고유형 선택
    select_element = driver.find_element(By.NAME, 'ReportTypeSelect')
    select = Select(select_element)
    select.select_by_value("01") #도로, 시설물 파손 및 고장 선택
    #time.sleep(1.5) #영상 촬영을 위한 딜레이

    # 제목 입력
    title_box = driver.find_element(By.CSS_SELECTOR, "#C_A_TITLE")
    title_box.click()
    title_box.send_keys(Reprot_TITLE) #제목 입력
    #time.sleep(1.5) #영상 촬영을 위한 딜레이
    
    # 신고내용 입력
    content_box = driver.find_element(By.CSS_SELECTOR, '#C_A_CONTENTS')
    content_box.click()
    content_box.send_keys(Reprot_Content) #신고내용 입력
    #time.sleep(1.5) #영상 촬영을 위한 딜레이
    
    #주소입력
    address_box = driver.find_element(By.CSS_SELECTOR, "#btnFindLoc")
    address_box.send_keys(Keys.CONTROL + "\n")
    time.sleep(1)
    
    #창 전환
    #print(driver.window_handles) #창 전환 확인
    driver.switch_to.window(driver.window_handles[1])
    time.sleep(0.5)
    
    driver.switch_to.frame("__daum__viewerFrame_1") #프레임 변경
    
    #주소 입력
    input_box = driver.find_element(By.NAME, "region_name")
    input_box.send_keys(address)
    input_box.send_keys(Keys.RETURN) #검색
    time.sleep(1.5)
    
    #첫번째 주소 클릭
    select_adress = driver.find_element(By.CSS_SELECTOR, "body > div.daum_popup.focus_input.focus_content.mapping_auto_road.mapping_auto_jibun.use_suggest.theme.bit_0.sit_1.sgit_0.sbit_0.pit_0.mit_0.lcit_0 > div > div.popup_body > ul > li > dl > dd.info_address.info_fst.main_address.main_road > span > button")
    select_adress.click()
    
    #창 전환
    driver.switch_to.window(driver.window_handles[0])
    time.sleep(1.5)
    
    #신청 버튼 클릭 (신고)
    driver.switch_to.default_content() #프레임 변경
    #time.sleep(1.5) #영상 촬영을 위한 딜레이
    
    report_box = driver.find_element(By.CSS_SELECTOR, "#frmSafeReport > div.tab > article > div > div.buttonArea.center > a.button.big.blue")
    report_box.click()
    
    
if __name__ == "__main__":
    #반복을 어떻게 할지 maybe try catch문으로 정보가 API를 타고 들어오면 실행 아니면 계속 반복 실행 or 대기
    info = get_user() #서버로부터 포트홀 정보 받아오기
    address = geocoding_reverse(info[0]['latitude'],info[0]['longitude']) #좌표를 주소로 변환
    F_address = format_address(address) #주소를 검색할 수 있는 형태로 변환
    time.sleep(0.5)
    
    login(driver, info[0]['account'], info[0]['password']) #로그인
    navigate_to_report_page(driver, URL_report) #신고페이지로 이동
    handle_alert(driver) #경고창 제어
    time.sleep(1)
    reportFLOW(F_address) #신고
    #accept_alert(driver) #경고창 제어
    time.sleep(2)
    #report(info[0]['report_id']) #신고 결과 서버로 전송


#신고 FLOW (Targeting)
#안전분야 신고유형 : 2번 인덱스 선택 #ReportTypeSelect(유형)
#사진/동영상 : ??
#신고발생지역 : 좌표를 주소로 변환 -> 위치 찾기 클릭 -> 주소 입력 -> 검색 
#(정확한 위치로 찍을 수 있을것인가? 주소로 검색하면 주위의 아무곳이나 뜬다)
#제목 : 포트홀 신고 #C_A_TITLE
#신고내용 : 포트홀 #C_A_CONTENTS
#신청 버튼 클릭 (신고)
    # #이미지 첨부
    # driver.switch_to.frame("raonkuploader_frame_kupload1") #프레임 변경
    # driver.find_element(By.ID,'button_add').click()
    # time.sleep(3)
    
    # #사진 선택
    # keyboard = Controller()
    # keyboard.type("C:\\Users\\lab32\\OneDrive\\바탕 화면\\report\\image\\example.png")
    # keyboard.press(Key.enter)
    # keyboard.release(Key.enter)
    # time.sleep(2)