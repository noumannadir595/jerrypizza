import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'config.dart';
import 'models.dart';
import 'providers.dart';
import 'services.dart';

// ==================== HELPERS ====================
double startPrice(ProductModel p) {
  if (p.sizes.isEmpty) return p.basePrice;
  return p.sizes.map((s) => s.price).reduce((a, b) => a < b ? a : b);
}

String shortOrderId(String id) =>
    id.length > 6 ? id.substring(id.length - 6).toUpperCase() : id.toUpperCase();

List<BoxShadow> softShadow([double opacity = 0.06]) => [
      BoxShadow(
        color: Colors.black.withValues(alpha: opacity),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ];

// ==================== APP BUTTON ====================
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = isLoading || onPressed == null;

    if (isOutlined) {
      return SizedBox(
        width: width ?? double.infinity,
        height: height ?? AppSizes.btnLarge,
        child: OutlinedButton(
          onPressed: disabled ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: textColor ?? AppColors.primary,
            side: BorderSide(
              color: disabled ? AppColors.textHint : AppColors.primary,
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.r16),
            ),
          ),
          child: _buildChild(),
        ),
      );
    }

    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? AppSizes.btnLarge,
      child: ElevatedButton(
        onPressed: disabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.primary,
          foregroundColor: textColor ?? AppColors.textWhite,
          disabledBackgroundColor: AppColors.textHint,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.r16),
          ),
        ),
        child: _buildChild(),
      ),
    );
  }

  Widget _buildChild() {
    if (isLoading) {
      return const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.textWhite),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: AppSizes.i20),
          const SizedBox(width: AppSizes.s8),
          Text(text, style: AppTextStyles.button),
        ],
      );
    }

    return Text(text, style: AppTextStyles.button);
  }
}

// ==================== APP TEXTFIELD ====================
class AppTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final bool isPassword;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int? maxLines;
  final int? maxLength;
  final bool isEnabled;
  final bool readOnly;
  final VoidCallback? onTap;
  final TextInputAction textInputAction;
  final FocusNode? focusNode;

  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.isPassword = false,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.maxLength,
    this.isEnabled = true,
    this.readOnly = false,
    this.onTap,
    this.textInputAction = TextInputAction.next,
    this.focusNode,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: AppTextStyles.label.copyWith(
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: AppSizes.s8),
        ],
        TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          obscureText: widget.isPassword ? _obscure : false,
          validator: widget.validator,
          onChanged: widget.onChanged,
          maxLines: widget.isPassword ? 1 : widget.maxLines,
          maxLength: widget.maxLength,
          enabled: widget.isEnabled,
          readOnly: widget.readOnly,
          onTap: widget.onTap,
          textInputAction: widget.textInputAction,
          focusNode: widget.focusNode,
          style: AppTextStyles.body.copyWith(
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            counterText: '',
            prefixIcon: widget.prefixIcon != null
                ? Icon(
                    widget.prefixIcon,
                    color: AppColors.textSecondary,
                    size: AppSizes.i20,
                  )
                : null,
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.textSecondary,
                      size: AppSizes.i20,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  )
                : widget.suffixIcon,
          ),
        ),
      ],
    );
  }
}

// ==================== APP IMAGE ====================
class AppImage extends StatelessWidget {
  final String url;
  final String imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double radius;
  final IconData placeholderIcon;

  const AppImage({
    super.key,
    this.url = '',
    this.imagePath = '',
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.radius = 0,
    this.placeholderIcon = Icons.local_pizza,
  });

  @override
  Widget build(BuildContext context) {
    if (url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: CachedNetworkImage(
          imageUrl: url,
          width: width,
          height: height,
          fit: fit,
          placeholder: (context, url) => _placeholder(),
          errorWidget: (context, url, error) => _placeholder(),
        ),
      );
    }

    if (imagePath.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.asset(
          imagePath,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => _placeholder(),
        ),
      );
    }

    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      color: AppColors.shimmer,
      child: Icon(
        placeholderIcon,
        color: AppColors.textHint,
        size: (width != null && width! < 100) ? 30 : 50,
      ),
    );
  }
}

// ==================== LOADING ====================
class AppLoading extends StatelessWidget {
  final String? message;
  const AppLoading({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          if (message != null) ...[
            const SizedBox(height: AppSizes.s16),
            Text(message!, style: AppTextStyles.body),
          ],
        ],
      ),
    );
  }
}

// ==================== EMPTY ====================
class AppEmpty extends StatelessWidget {
  final String? title;
  final String? message;
  final IconData icon;
  final String? buttonText;
  final VoidCallback? onButtonPressed;

  const AppEmpty({
    super.key,
    this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.buttonText,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.p32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.p24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 64, color: AppColors.primary),
            ),
            const SizedBox(height: AppSizes.s24),
            Text(
              title ?? 'Nothing here',
              style: AppTextStyles.headingSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.s8),
            Text(
              message ?? 'Check back later',
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
            if (buttonText != null && onButtonPressed != null) ...[
              const SizedBox(height: AppSizes.s24),
              AppButton(
                text: buttonText!,
                onPressed: onButtonPressed,
                width: 200,
                height: AppSizes.btnMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ==================== ERROR ====================
class AppError extends StatelessWidget {
  final String? title;
  final String? message;
  final VoidCallback? onRetry;

  const AppError({super.key, this.title, this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.p32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.p24),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppSizes.s24),
            Text(
              title ?? 'Oops! Something went wrong',
              style: AppTextStyles.headingSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.s8),
            Text(
              message ?? 'Please try again later',
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSizes.s24),
              AppButton(
                text: 'Try Again',
                onPressed: onRetry,
                icon: Icons.refresh,
                width: 200,
                height: AppSizes.btnMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ==================== PRESS ANIMATION ====================
class ScaleTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const ScaleTap({super.key, required this.child, this.onTap});

  @override
  State<ScaleTap> createState() => _ScaleTapState();
}

class _ScaleTapState extends State<ScaleTap> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) {
        setState(() => _down = false);
        widget.onTap?.call();
      },
      child: AnimatedScale(
        scale: _down ? 0.96 : 1,
        duration: const Duration(milliseconds: 120),
        child: widget.child,
      ),
    );
  }
}

// ==================== QUICK ADD ====================
void quickAdd(BuildContext context, WidgetRef ref, ProductModel p,
    {String? heroTag}) {
  if (!p.isAvailable) {
    Helpers.snack(context, '${p.name} is sold out right now');
    return;
  }
  if (p.sizes.length > 1 || p.addons.isNotEmpty) {
    context.push('/product/${p.id}', extra: heroTag);
    return;
  }
  ref.read(cartProvider.notifier).add(CartItemModel(
        productId: p.id,
        name: p.name,
        imagePath: p.imagePath,
        sizeName: p.sizes.isEmpty ? null : p.sizes.first.name,
        unitPrice: p.sizes.isEmpty ? p.basePrice : p.sizes.first.price,
      ));
  Helpers.success(context, '${p.name} added to cart');
}

// ==================== SMALL ROUND ADD BUTTON ====================
class AddCircleButton extends StatelessWidget {
  final VoidCallback onTap;
  const AddCircleButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ScaleTap(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 20),
      ),
    );
  }
}

// ==================== FOOD CARD ====================
class FoodCard extends ConsumerWidget {
  final ProductModel product;
  final String heroTag;
  final double width;
  const FoodCard({
    super.key,
    required this.product,
    required this.heroTag,
    this.width = 172,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = product;
    return ScaleTap(
      onTap: () => context.push('/product/${p.id}', extra: heroTag),
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(22),
          boxShadow: softShadow(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Hero(
                  tag: heroTag,
                  child: AppImage(
                    imagePath: p.imagePath,
                    width: width,
                    height: 124,
                    radius: 22,
                  ),
                ),
                if (p.isPopular)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('POPULAR',
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.black)),
                    ),
                  ),
                if (!p.isAvailable)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      alignment: Alignment.center,
                      child: const Text('SOLD OUT',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1)),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelBold),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${p.sizes.length > 1 ? "From " : ""}${Formatters.price(startPrice(p))}',
                          style: AppTextStyles.priceSmall
                              .copyWith(color: AppColors.primary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      AddCircleButton(
                          onTap: () =>
                              quickAdd(context, ref, p, heroTag: heroTag)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== PRODUCT TILE ====================
class ProductTile extends ConsumerWidget {
  final ProductModel product;
  final String heroTag;
  final int index;
  const ProductTile({
    super.key,
    required this.product,
    required this.heroTag,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = product;
    final favs = ref.watch(favoriteIdsProvider).valueOrNull ?? <String>{};
    final isFav = favs.contains(p.id);

    return ScaleTap(
      onTap: () => context.push('/product/${p.id}', extra: heroTag),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(22),
          boxShadow: softShadow(),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Hero(
                  tag: heroTag,
                  child: AppImage(
                    imagePath: p.imagePath,
                    width: 98,
                    height: 98,
                    radius: 16,
                  ),
                ),
                if (!p.isAvailable)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: const Text('SOLD OUT',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(p.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.labelBold),
                      ),
                      GestureDetector(
                        onTap: () async {
                          final uid = AuthService.uid;
                          if (uid == null) {
                            Helpers.snack(
                                context, 'Log in to save favorites');
                            return;
                          }
                          await FirestoreService.toggleFavorite(uid, p.id);
                        },
                        child: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          size: 20,
                          color:
                              isFav ? AppColors.primary : AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(p.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${p.sizes.length > 1 ? "From " : ""}${Formatters.price(startPrice(p))}',
                          style: AppTextStyles.priceSmall
                              .copyWith(color: AppColors.primary),
                        ),
                      ),
                      AddCircleButton(
                          onTap: () =>
                              quickAdd(context, ref, p, heroTag: heroTag)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: (40 * (index > 8 ? 8 : index)).ms)
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.08, end: 0);
  }
}

// ==================== PRODUCT CARD ====================
class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;
  final double? width;
  final double? imageHeight;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.width,
    this.imageHeight,
  });

  @override
  Widget build(BuildContext context) {
    final cardWidth = width ?? 160;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardWidth,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppSizes.r16),
          boxShadow: softShadow(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AppImage(
                  imagePath: product.imagePath,
                  width: cardWidth,
                  height: imageHeight ?? 120,
                  radius: AppSizes.r16,
                ),
                if (product.isPopular)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(AppSizes.r8),
                      ),
                      child: const Text(
                        'POPULAR',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppSizes.p12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: AppTextStyles.labelBold,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSizes.s4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        Formatters.price(product.basePrice),
                        style: AppTextStyles.priceSmall,
                      ),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== DEAL CARD ====================
class DealCard extends StatelessWidget {
  final DealModel deal;
  final VoidCallback onTap;

  const DealCard({super.key, required this.deal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 260,
        margin: const EdgeInsets.only(right: AppSizes.s12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppSizes.r16),
          boxShadow: softShadow(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AppImage(
                  imagePath: deal.imagePath,
                  width: 260,
                  height: 120,
                  radius: AppSizes.r16,
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppColors.accentGradient,
                      borderRadius: BorderRadius.circular(AppSizes.r8),
                    ),
                    child: const Text(
                      'DEAL',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppSizes.p12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deal.title,
                    style: AppTextStyles.labelBold,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    deal.description,
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSizes.s8),
                  Row(
                    children: [
                      Text(
                        Formatters.price(deal.price),
                        style: AppTextStyles.price,
                      ),
                      if (deal.originalPrice > 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          Formatters.price(deal.originalPrice),
                          style: AppTextStyles.caption.copyWith(
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== FLOATING CART BAR ====================
class CartBar extends ConsumerWidget {
  const CartBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(cartCountProvider);
    final subtotal = ref.watch(cartSubtotalProvider);
    if (count == 0) return const SizedBox.shrink();

    return ScaleTap(
      onTap: () {
        ref.read(navIndexProvider.notifier).state = 2;
        context.go('/home');
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(10),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (c, a) =>
                    ScaleTransition(scale: a, child: c),
                child: Text('$count',
                    key: ValueKey(count),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('View Cart',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15)),
            ),
            Text(Formatters.price(subtotal),
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
          ],
        ),
      ),
    )
        .animate()
        .slideY(begin: 1, end: 0, duration: 350.ms, curve: Curves.easeOutBack)
        .fadeIn();
  }
}

// ==================== SECTION TITLE ====================
class SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const SectionTitle(this.title, {super.key, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        children: [
          Expanded(
              child: Text(title,
                  style: AppTextStyles.heading.copyWith(fontSize: 20))),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(action!,
                  style: AppTextStyles.label.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }
}

// ==================== SECTION HEADER ====================
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onViewAll;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.heading.copyWith(fontSize: 22),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: AppTextStyles.caption),
                ],
              ],
            ),
          ),
          if (onViewAll != null)
            TextButton(
              onPressed: onViewAll,
              child: Row(
                children: [
                  Text(
                    'View All',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ==================== INFO / WARNING BANNER ====================
class InfoBanner extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;
  const InfoBanner(this.text,
      {super.key,
      this.color = AppColors.warning,
      this.icon = Icons.info_outline});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppTextStyles.label)),
        ],
      ),
    );
  }
}

// ==================== BILL ROW ====================
class BillRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;
  const BillRow(this.label, this.value,
      {super.key, this.bold = false, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: bold ? AppTextStyles.headingSmall : AppTextStyles.body),
          Text(
            value,
            style: bold
                ? AppTextStyles.price.copyWith(color: AppColors.primary)
                : AppTextStyles.body.copyWith(color: valueColor),
          ),
        ],
      ),
    );
  }
}

// ==================== OFFLINE BANNER ====================
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(onlineProvider).valueOrNull ?? true;
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      child: online
          ? const SizedBox(width: double.infinity)
          : Container(
              width: double.infinity,
              color: AppColors.error,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: const SafeArea(
                bottom: false,
                child: Text('No internet connection',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ),
    );
  }
}

// ==================== QUANTITY BUTTON ====================
class QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const QuantityButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppSizes.r10),
          border: Border.all(color: AppColors.divider),
        ),
        child: Icon(icon, size: 18, color: AppColors.primary),
      ),
    );
  }
}

// ==================== STATUS BADGE ====================
class StatusBadge extends StatelessWidget {
  final String status;
  final Color color;

  const StatusBadge({
    super.key,
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSizes.rFull),
      ),
      child: Text(
        status,
        style: AppTextStyles.captionSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ==================== SHIMMER ====================
class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = AppSizes.r8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.shimmer,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class ProductCardShimmer extends StatelessWidget {
  const ProductCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: AppSizes.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          ShimmerBox(width: 160, height: 120, borderRadius: AppSizes.r16),
          SizedBox(height: AppSizes.s8),
          ShimmerBox(width: 120, height: 14),
          SizedBox(height: AppSizes.s4),
          ShimmerBox(width: 80, height: 12),
        ],
      ),
    );
  }
}

// ==================== CONFIRM DIALOG ====================
class AppDialog {
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.r20),
        ),
        title: Text(title, style: AppTextStyles.headingSmall),
        content: Text(message, style: AppTextStyles.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              cancelText,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isDestructive ? AppColors.error : AppColors.primary,
              minimumSize: const Size(80, 40),
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}