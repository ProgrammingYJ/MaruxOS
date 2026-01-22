# Contributing to MaruxOS

**[English](#english) | [한국어](#한국어)**

---

# English

Thank you for your interest in contributing to MaruxOS!

## Code of Conduct

- Be respectful and inclusive
- Welcome newcomers and beginners
- Focus on constructive feedback
- Collaborate in good faith

## How to Contribute

### Reporting Bugs

Before creating a bug report:
1. Check if the bug has already been reported
2. Test with the latest version
3. Gather necessary information

Include in your bug report:
- **Description**: Clear description of the issue
- **Steps to Reproduce**: Detailed steps to recreate the bug
- **Expected Behavior**: What should happen
- **Actual Behavior**: What actually happens
- **System Information**:
  - MaruxOS version
  - Hardware specifications
- **Logs**: Relevant error messages or logs
- **Screenshots**: If applicable

### Suggesting Features

Feature requests are welcome! Include:
- **Use Case**: Why is this feature needed?
- **Description**: What should the feature do?
- **Benefits**: How does it improve MaruxOS?
- **Implementation Ideas**: If you have any suggestions

### Contributing Code

#### Getting Started

1. **Fork the repository**
2. **Clone your fork**:
   ```bash
   git clone https://github.com/yourusername/maruxos.git
   cd maruxos
   ```
3. **Create a branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

#### Making Changes

1. **Make your changes** following our coding standards
2. **Test your changes** thoroughly
3. **Commit your changes**:
   ```bash
   git add .
   git commit -m "feat: Add feature description"
   ```

#### Commit Message Guidelines

Format: `type: description`

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

Examples:
```
feat: Add Korean language support
fix: Resolve network initialization issue
docs: Update build guide
refactor: Simplify xinitrc script
```

#### Code Style

**Shell Scripts**:
- Use `#!/bin/sh` or `#!/bin/bash` shebang
- Add `set -e` for error handling
- Use meaningful variable names
- Comment complex sections

```bash
#!/bin/sh
# Script Purpose
# ==============

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Clear description of what this does
do_something() {
    local param="$1"
    echo "Processing: $param"
}
```

#### Testing

Before submitting:

1. **Build Test**: Ensure squashfs and ISO creation works
   ```bash
   sudo mksquashfs rootfs-lfs iso-build/live/filesystem.squashfs -comp gzip -e boot -noappend
   sudo grub-mkrescue -o MaruxOS-1.0.iso iso-build
   ```

2. **VM Test**: Test ISO in virtual machine (VirtualBox, QEMU)

3. **Functional Test**: Verify your changes work as intended

#### Submitting Pull Request

1. **Push your branch**:
   ```bash
   git push origin feature/your-feature-name
   ```

2. **Create Pull Request** on GitHub

3. **Fill PR template** with:
   - Description of changes
   - Related issues
   - Testing done
   - Screenshots (if UI changes)

4. **Wait for review** and address feedback

### Contributing Documentation

Documentation improvements are always welcome!

- Fix typos and grammar
- Improve clarity
- Add missing information
- Update outdated content
- Translate documentation (English/Korean)

### Contributing Designs

Visual improvements (coordinate with **tuna27** for design consistency):
- Icons
- Wallpapers
- Themes

Submit in `MaruxOS 디자인/` directory with:
- High resolution (1920x1080+ for wallpapers)
- PNG format for transparency
- Matching existing color scheme

## Areas Needing Contribution

### High Priority

- [ ] Disk installation support
- [ ] Package management system
- [ ] Improve documentation
- [ ] Boot time optimization

### Medium Priority

- [ ] Add language support
- [ ] GUI file manager
- [ ] ARM architecture support

### Low Priority

- [ ] Custom wallpapers
- [ ] Additional applications
- [ ] Icon themes

## Important Notes

### Build Environment

MaruxOS is built using **Linux From Scratch (LFS) 12.1**, NOT Debian/Ubuntu. Key differences:
- No apt/package manager
- All software compiled from source
- squashfs must use **gzip** compression (kernel doesn't support xz)

### Contact

- **Discord**: `pizzamaru_`
- **Email**: marudev@outlook.kr
- **Portfolio**: https://marulee.dev
- **GitHub Issues**: Bug reports and feature requests

## Credits

| Role | Credit |
|------|--------|
| **UI/UX Design** | **tuna27** |
| **AI Development** | **Claude Code (Anthropic)** |
| Base System | Linux From Scratch |
| Kernel | kernel.org |

**Special Thanks**: Sigterm Co., Ltd. - For sponsoring Claude Code MAX plan

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

# 한국어

MaruxOS에 관심을 가져주셔서 감사합니다!

## 행동 강령

- 존중하고 포용적으로 행동
- 초보자와 신규 참여자 환영
- 건설적인 피드백에 집중
- 선의로 협력

## 기여 방법

### 버그 리포트

버그 리포트 작성 전:
1. 이미 보고된 버그인지 확인
2. 최신 버전으로 테스트
3. 필요한 정보 수집

버그 리포트에 포함할 내용:
- **설명**: 문제에 대한 명확한 설명
- **재현 단계**: 버그를 재현하는 상세 단계
- **예상 동작**: 어떻게 동작해야 하는지
- **실제 동작**: 실제로 어떻게 동작하는지
- **시스템 정보**:
  - MaruxOS 버전
  - 하드웨어 사양
- **로그**: 관련 오류 메시지나 로그
- **스크린샷**: 해당되는 경우

### 기능 제안

기능 요청 환영합니다! 포함할 내용:
- **사용 사례**: 왜 이 기능이 필요한가?
- **설명**: 기능이 무엇을 해야 하는가?
- **이점**: MaruxOS를 어떻게 개선하는가?

### 코드 기여

#### 커밋 메시지 가이드라인

형식: `type: description`

타입:
- `feat`: 새 기능
- `fix`: 버그 수정
- `docs`: 문서 변경
- `style`: 코드 스타일 변경
- `refactor`: 코드 리팩토링
- `chore`: 유지보수 작업

#### 테스트

제출 전:

1. **빌드 테스트**: squashfs 및 ISO 생성 확인
   ```bash
   sudo mksquashfs rootfs-lfs iso-build/live/filesystem.squashfs -comp gzip -e boot -noappend
   sudo grub-mkrescue -o MaruxOS-1.0.iso iso-build
   ```

2. **VM 테스트**: 가상 머신에서 ISO 테스트

### 문서 기여

문서 개선 환영합니다!

- 오타 및 문법 수정
- 명확성 개선
- 누락된 정보 추가
- 번역 (영어/한국어)

### 디자인 기여

디자인 일관성을 위해 **tuna27**과 협의 권장:
- 아이콘
- 배경화면
- 테마

## 중요 참고 사항

### 빌드 환경

MaruxOS는 **Linux From Scratch (LFS) 12.1** 기반입니다 (Debian/Ubuntu 아님):
- apt/패키지 관리자 없음
- 모든 소프트웨어 소스에서 컴파일
- squashfs는 **gzip** 압축 필수 (커널이 xz 미지원)

### 연락처

- **Discord**: `pizzamaru_`
- **Email**: marudev@outlook.kr
- **Portfolio**: https://marulee.dev
- **GitHub Issues**: 버그 리포트 및 기능 요청

## 크레딧

| 역할 | 크레딧 |
|------|--------|
| **UI/UX 디자인** | **tuna27** |
| **AI 개발** | **Claude Code (Anthropic)** |
| 베이스 시스템 | Linux From Scratch |
| 커널 | kernel.org |

**감사의 말**: Sigterm Co., Ltd. (시그텀 주식회사) - Claude Code MAX 플랜 지원

## 라이선스

기여함으로써 귀하의 기여가 MIT 라이선스에 따라 라이선스됨에 동의합니다.

---

**MaruxOS에 기여해 주셔서 감사합니다!**
