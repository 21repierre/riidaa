<h1 align="center">リーダー</h1>
<h3 align="center">A manga reader with support for <a href="https://github.com/yomidevs/yomitan">Yomitan</a> dictionaries</h3>
<p align="center">
	<img src="./assets/logo.png" width="20%">
	<br>
	<a href="https://apps.apple.com/us/app/%E3%83%AA%E3%83%BC%E3%83%80%E3%83%BC/id6747406845">
		<img src="https://upload.wikimedia.org/wikipedia/commons/thumb/3/3c/Download_on_the_App_Store_Badge.svg/1200px-Download_on_the_App_Store_Badge.svg.png" width="20%">
	</a>
</p>

## Features

- Create manga titles using Anilist API
- Add volumes that have been OCRed with mokuro (see [volume format](#volume-format))
- Import Yomitan dictionaries
- Click on a text box when reading to pop up the sentence with definitions
- Change the appearance of the text boxes

## TODO

- Update dictionary
- Manually offset term length in parser view

## Volume format

When doing the OCR make sure the volume format is `<title> v<number>` (e.g. "*One Piece v012*"). You can also manualy edit the *mokuro* file after the OCR.

Then, rename the *mokuro* file using the same format (e.g. "*One Piece v012.mokuro*"). 

Also create a directory with the same name (e.g. "*One Piece v012*"). Put the volume's images inside this folder (e.g. "*One Piece v012/143.jpg*").

Finally, zip the folder and the *mokuro* file and you are good to go!
