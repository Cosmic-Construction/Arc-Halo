#!/usr/bin/env python3
"""
Arc-Halo Cognitive Fusion Reactor - Database Connection Test
Tests the connection to the Neon database and verifies schema deployment
"""

import os
import sys
from datetime import datetime

try:
    import psycopg2
    from psycopg2.extras import RealDictCursor
except ImportError:
    print("Error: psycopg2 not installed. Run: pip install psycopg2-binary")
    sys.exit(1)


def test_connection(connection_string):
    """Test basic database connection"""
    try:
        conn = psycopg2.connect(connection_string)
        print("✅ Database connection successful")
        
        with conn.cursor() as cursor:
            cursor.execute("SELECT version();")
            version = cursor.fetchone()[0]
            print(f"   PostgreSQL version: {version.split(',')[0]}")
        
        conn.close()
        return True
    except Exception as e:
        print(f"❌ Database connection failed: {e}")
        return False


def test_extensions(connection_string):
    """Test required extensions"""
    try:
        conn = psycopg2.connect(connection_string)
        print("\n✅ Checking extensions...")
        
        with conn.cursor(cursor_factory=RealDictCursor) as cursor:
            cursor.execute("""
                SELECT extname, extversion 
                FROM pg_extension 
                WHERE extname IN ('uuid-ossp', 'vector')
                ORDER BY extname;
            """)
            extensions = cursor.fetchall()
            
            for ext in extensions:
                print(f"   ✓ {ext['extname']} version {ext['extversion']}")
            
            # Check for uuid-ossp specifically
            cursor.execute("""
                SELECT COUNT(*) as count 
                FROM pg_extension 
                WHERE extname = 'uuid-ossp';
            """)
            if cursor.fetchone()['count'] == 0:
                print("   ⚠ uuid-ossp extension not installed (required)")
                return False
        
        conn.close()
        return True
    except Exception as e:
        print(f"❌ Extension check failed: {e}")
        return False


def test_tables(connection_string):
    """Test that all required tables exist"""
    required_tables = [
        'models',
        'transformer_layers',
        'attention_heads',
        'tensor_metadata',
        'tensor_data',
        'model_weights',
        'embeddings',
        'training_sessions',
        'training_metrics',
        'optimizer_state',
        'model_checkpoints',
        'gradient_checkpoints',
        'inference_sessions',
        'activation_cache',
        'kv_cache',
        'inference_metrics',
        'attention_patterns',
        'cognitive_fusion_reactors',
        'reactor_models',
        'fusion_operations',
        'model_interaction_graph',
        'cognitive_state',
        'reactor_metrics'
    ]
    
    try:
        conn = psycopg2.connect(connection_string)
        print("\n✅ Checking schema tables...")
        
        with conn.cursor(cursor_factory=RealDictCursor) as cursor:
            cursor.execute("""
                SELECT table_name 
                FROM information_schema.tables 
                WHERE table_schema = 'public' 
                AND table_type = 'BASE TABLE'
                ORDER BY table_name;
            """)
            existing_tables = [row['table_name'] for row in cursor.fetchall()]
            
            print(f"   Found {len(existing_tables)} tables total")
            
            missing_tables = set(required_tables) - set(existing_tables)
            if missing_tables:
                print(f"   ⚠ Missing tables: {', '.join(missing_tables)}")
                return False
            else:
                print(f"   ✓ All {len(required_tables)} required tables exist")
        
        conn.close()
        return True
    except Exception as e:
        print(f"❌ Table check failed: {e}")
        return False


def test_views(connection_string):
    """Test that database views exist"""
    required_views = [
        'v_model_architecture',
        'v_training_progress',
        'v_reactor_status'
    ]
    
    try:
        conn = psycopg2.connect(connection_string)
        print("\n✅ Checking database views...")
        
        with conn.cursor(cursor_factory=RealDictCursor) as cursor:
            cursor.execute("""
                SELECT table_name 
                FROM information_schema.views 
                WHERE table_schema = 'public'
                ORDER BY table_name;
            """)
            existing_views = [row['table_name'] for row in cursor.fetchall()]
            
            missing_views = set(required_views) - set(existing_views)
            if missing_views:
                print(f"   ⚠ Missing views: {', '.join(missing_views)}")
                print("   (Views may not be created if using individual schema files)")
                # Views are optional, so we don't return False
            else:
                print(f"   ✓ All {len(required_views)} views exist")
        
        conn.close()
        return True
    except Exception as e:
        print(f"❌ View check failed: {e}")
        return False


def test_functions(connection_string):
    """Test that helper functions exist"""
    try:
        conn = psycopg2.connect(connection_string)
        print("\n✅ Checking database functions...")
        
        with conn.cursor(cursor_factory=RealDictCursor) as cursor:
            cursor.execute("""
                SELECT proname 
                FROM pg_proc 
                WHERE proname IN ('calculate_model_parameters', 'get_latest_checkpoint', 'update_updated_at_column')
                ORDER BY proname;
            """)
            functions = [row['proname'] for row in cursor.fetchall()]
            
            if functions:
                print(f"   ✓ Found {len(functions)} helper functions")
            else:
                print("   ⚠ No helper functions found (may not be created with individual schema files)")
        
        conn.close()
        return True
    except Exception as e:
        print(f"❌ Function check failed: {e}")
        return False


def test_sample_query(connection_string):
    """Test a sample query"""
    try:
        conn = psycopg2.connect(connection_string)
        print("\n✅ Running sample queries...")
        
        with conn.cursor(cursor_factory=RealDictCursor) as cursor:
            # Count models
            cursor.execute("SELECT COUNT(*) as count FROM models;")
            model_count = cursor.fetchone()['count']
            print(f"   Models in database: {model_count}")
            
            # Count reactors
            cursor.execute("SELECT COUNT(*) as count FROM cognitive_fusion_reactors;")
            reactor_count = cursor.fetchone()['count']
            print(f"   Reactors in database: {reactor_count}")
            
            # Count training sessions
            cursor.execute("SELECT COUNT(*) as count FROM training_sessions;")
            session_count = cursor.fetchone()['count']
            print(f"   Training sessions: {session_count}")
        
        conn.close()
        return True
    except Exception as e:
        print(f"❌ Sample query failed: {e}")
        return False


def main():
    print("╔═══════════════════════════════════════════════════════════╗")
    print("║   Arc-Halo Cognitive Fusion Reactor - Connection Test    ║")
    print("╚═══════════════════════════════════════════════════════════╝")
    print(f"\nTest started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    # Get connection string from environment
    connection_string = os.getenv('NEON_DATABASE_URL')
    
    if not connection_string:
        print("\n❌ Error: NEON_DATABASE_URL environment variable not set")
        print("   Set it with: export NEON_DATABASE_URL='postgresql://...'")
        print("   Or configure it in db/config/.env")
        sys.exit(1)
    
    # Mask password in display
    display_url = connection_string.split('@')[0].split(':')[0] + ":****@" + connection_string.split('@')[1]
    print(f"Database URL: {display_url}")
    
    # Run tests
    results = []
    results.append(("Connection", test_connection(connection_string)))
    results.append(("Extensions", test_extensions(connection_string)))
    results.append(("Tables", test_tables(connection_string)))
    results.append(("Views", test_views(connection_string)))
    results.append(("Functions", test_functions(connection_string)))
    results.append(("Sample Queries", test_sample_query(connection_string)))
    
    # Summary
    print("\n" + "="*60)
    print("TEST SUMMARY")
    print("="*60)
    
    passed = sum(1 for _, result in results if result)
    total = len(results)
    
    for test_name, result in results:
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"{test_name:.<40} {status}")
    
    print("="*60)
    print(f"Results: {passed}/{total} tests passed")
    
    if passed == total:
        print("\n🎉 All tests passed! Your database is ready for Arc-Halo.")
        sys.exit(0)
    else:
        print(f"\n⚠ {total - passed} test(s) failed. Please review the errors above.")
        sys.exit(1)


if __name__ == "__main__":
    main()
